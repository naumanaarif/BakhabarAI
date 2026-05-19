from google.adk.agents.invocation_context import InvocationContext
from google.adk.agents.run_config import RunConfig
from google.adk.sessions.session import Session
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.adk.events.event import Event
from google.adk.utils.context_utils import Aclosing
from typing import AsyncGenerator
import uuid
import os

async def create_root_context(agent) -> InvocationContext:
    """
    Creates a root invocation context for running an agent standalone.
    """
    session_service = InMemorySessionService()
    session_id = str(uuid.uuid4())
    app_name = "BakhabarAI"
    user_id = "anonymous"
    
    session = await session_service.get_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id
    )
    if not session:
        session = await session_service.create_session(
            app_name=app_name,
            user_id=user_id,
            session_id=session_id
        )
    
    # Minimal InvocationContext setup
    ctx = InvocationContext(
        invocation_id=str(uuid.uuid4()),
        session_service=session_service,
        session=session,
        agent=agent,
        branch="main",
        run_config=RunConfig()
    )
    return ctx

async def run_agent_standalone(agent, input_text: str) -> str:
    """
    Runs an agent standalone and returns the final response.
    Includes retry logic for RateLimitErrors.
    """
    from google.genai import types
    from tracer import tracer
    from google.cloud.firestore_v1 import GeoPoint
    import time
    import litellm
    import asyncio

    # Enable debug if env var is set
    if os.getenv("LITELLM_DEBUG", "False").lower() == "true":
        litellm._turn_on_debug()

    def sanitize_for_json(obj):
        """Recursively converts non-JSON serializable objects (like GeoPoint) to dicts."""
        if isinstance(obj, dict):
            return {k: sanitize_for_json(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [sanitize_for_json(item) for item in obj]
        elif isinstance(obj, GeoPoint):
            return {"lat": obj.latitude, "lng": obj.longitude}
        return obj
    
    print(f"DEBUG: Starting standalone run for agent: {agent.name}")
    from .model_config import set_key_for_agent
    set_key_for_agent(agent.name)

    def clean_event_text(text: str) -> str:
        import json
        import re
        text = text.strip()
        if not text:
            return ""
            
        # If it looks like raw JSON or contains a JSON block
        if text.startswith("{") or "```json" in text:
            try:
                # Extract from code block if present
                json_str = text
                if "```json" in text:
                    json_str = text.split("```json")[1].split("```")[0].strip()
                
                data = json.loads(json_str)
                if isinstance(data, dict):
                    # Prioritize human-readable fields
                    for key in ["summary", "description", "message", "status", "report", "crisis_type", "action_type"]:
                        if key in data and isinstance(data[key], str) and len(data[key]) > 2:
                            return data[key]
                    # If it's an evaluations list (SignalFusion)
                    if "evaluations" in data:
                        return f"Evaluated {len(data['evaluations'])} emergency signals."
                    # If it's a classifications list (Detector)
                    if "classifications" in data:
                        return f"Classified {len(data['classifications'])} active incidents."
                return "Processed structured data and committed to database."
            except:
                pass

        # If it's just plain text, clean it up
        cleaned = re.sub(r'[\*\#_`\-]', '', text)
        cleaned = re.sub(r'\s+', ' ', cleaned).strip()
        
        # If still too long or looks like code/JSON, summarize
        if "{" in cleaned or len(cleaned) > 200:
            if len(cleaned) > 197:
                return cleaned[:197] + "..."
            return cleaned
            
        return cleaned if cleaned else "Thinking..."

    max_retries = 3
    retry_delay = 5 # seconds
    
    for attempt in range(max_retries):
        start_run = time.time()
        ctx = await create_root_context(agent)
        
        # Log the user input to tracer for UI (Summarized to avoid JSON clutter)
        display_input = input_text
        if len(display_input) > 150:
            # If it's a prompt with JSON, just show the core request
            if "pending signals" in display_input.lower():
                display_input = "Analyzing pending signals and active incidents for autonomous response..."
            else:
                display_input = display_input[:147] + "..."

        user_action = f"Query: {display_input}" if input_text else "Initiated pipeline request"
        tracer.log(
            agent_name="User",
            action=user_action,
            input_data={"text": input_text[:500]}, # Store truncated raw text in input_data
            output_data={},
            confidence=1.0
        )
        
        # Add the input as the first and only event in this fresh session
        user_event = Event(
            author="user",
            content=types.Content(role="user", parts=[types.Part(text=input_text)]),
            invocation_id=ctx.invocation_id
        )
        await ctx.session_service.append_event(ctx.session, user_event)
        
        final_output = ""
        event_count = 0
        tool_call_count = 0
        max_tool_calls = 5 # Safety valve for Llama loops
        executed_tool_calls = set() # Prevent identical duplicate tool calls
        
        try:
            # Pass only the context to run_async
            async with Aclosing(agent.run_async(ctx)) as agen:
                async for event in agen:
                    event_count += 1
                    elapsed = time.time() - start_run
                    
                    if tool_call_count >= max_tool_calls:
                        print(f"CRITICAL: Agent {agent.name} exceeded max tool calls ({max_tool_calls}). Force-breaking generator.")
                        # Force close the generator to stop ADK internals
                        await agen.aclose()
                        break

                    if event.author != "user":
                        # Capture tool calls
                        tool_calls = []
                        event_text = ""
                        has_terminal_response = False

                        if hasattr(event, 'content') and event.content and hasattr(event.content, 'parts'):
                            for part in event.content.parts:
                                if tool_call_count >= max_tool_calls:
                                    print(f"CRITICAL: Agent {agent.name} exceeded max tool calls ({max_tool_calls}). Force-breaking part loop.")
                                    has_terminal_response = True
                                    break

                                if hasattr(part, 'call') and part.call:
                                    tool_call_count += 1
                                    call_hash = f"{part.call.name}:{json.dumps(part.call.args, sort_keys=True)}"
                                    if call_hash in executed_tool_calls:
                                        print(f"DEBUG: Skipping identical duplicate tool call: {part.call.name}")
                                        continue
                                    executed_tool_calls.add(call_hash)
                                    tool_calls.append({"tool": part.call.name, "args": part.call.args})
                                
                                elif hasattr(part, 'response') and part.response:
                                    res_str = str(part.response.result)
                                    if '"terminal": true' in res_str.lower() or '"DATA_LOCKED"' in res_str:
                                        has_terminal_response = True
                                    tool_calls.append({"tool_response": part.response.name, "result": part.response.result})
                                
                                elif hasattr(part, 'text') and part.text:
                                    event_text += part.text
                            
                            if tool_call_count >= max_tool_calls:
                                break

                        # Normal logging logic...
                        try:
                            action_desc = clean_event_text(event_text)
                            if has_terminal_response:
                                action_desc = "Task finalized. Committing results to dashboard."
                            
                            if not action_desc:
                                # (existing fallback logic)
                                if tool_calls:
                                    actions = []
                                    for tc in tool_calls:
                                        if "tool" in tc: actions.append(f"Running task: {tc['tool'].replace('_', ' ').title()}")
                                        if "tool_response" in tc: actions.append(f"Completed: {tc['tool_response'].replace('_', ' ').title()}")
                                    action_desc = " | ".join(actions)
                            
                            tracer.log(agent_name=event.author, action=action_desc or "AI processing", input_data={"tool_calls": tool_calls}, output_data=sanitize_for_json(event.model_dump()), confidence=1.0)
                        except Exception as e:
                            print(f"DEBUG: Error logging: {e}")

                        # If we just received a terminal tool response, we can break early if the model keeps talking
                        if has_terminal_response and tool_call_count >= 1:
                            print(f"DEBUG: Received terminal response from tool. Preparing to close agent {agent.name}.")
                            # We don't break immediately to allow the model to say "Processing complete"
                    
                    if hasattr(event, 'content') and event.content:
                        if hasattr(event.content, 'parts'):
                            for part in event.content.parts:
                                if hasattr(part, 'text') and part.text:
                                    final_output += part.text
            
            # If we reached here without exception, break the retry loop
            total_time = time.time() - start_run
            print(f"DEBUG: Pipeline finished in {total_time:.1f}s with {event_count} events.")
            return final_output

        except Exception as e:
            error_str = str(e)
            if "rate_limit" in error_str.lower() or "429" in error_str:
                print(f"DEBUG: Rate limit hit on attempt {attempt + 1}. Rotating key and retrying in {retry_delay}s...")
                from .model_config import rotate_groq_key
                rotate_groq_key()
                await asyncio.sleep(retry_delay)
                # Exponential backoff for next time
                retry_delay *= 2
            else:
                print(f"DEBUG: Exception during agent.run_async: {e}")
                raise e
    
    raise Exception(f"Failed to run agent {agent.name} after {max_retries} attempts due to Rate Limits.")
