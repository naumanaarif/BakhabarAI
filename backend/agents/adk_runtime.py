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
    """
    from google.genai import types
    from tracer import tracer
    from google.cloud.firestore_v1 import GeoPoint
    import time
    import litellm

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
    start_run = time.time()
    ctx = await create_root_context(agent)
    
    # DO NOT append user message to session_service if we want to save tokens.
    # The ADK will still see the input_text via the run_async if we pass it correctly or use a clean session.
    # For now, we just create a NEW session every time in create_root_context, but we must ensure
    # we don't bleed history.
    
    # Log the user input to tracer for UI
    tracer.log(
        agent_name="user",
        action="input_message",
        input_data={"text": input_text},
        output_data={},
        confidence=1.0
    )
    
    # Add the input as the first and only event in this fresh session
    from google.genai import types
    user_event = Event(
        author="user",
        content=types.Content(role="user", parts=[types.Part(text=input_text)]),
        invocation_id=ctx.invocation_id
    )
    await ctx.session_service.append_event(ctx.session, user_event)
    
    final_output = ""
    event_count = 0
    try:
        # Pass only the context to run_async
        async with Aclosing(agent.run_async(ctx)) as agen:
            async for event in agen:
                event_count += 1
                elapsed = time.time() - start_run
                print(f"DEBUG: [{elapsed:.1f}s] Received event {event_count} from {event.author}")
                
                # Log agent event to tracer
                if event.author != "user":
                    # Capture tool calls specifically for meaningful notifications
                    tool_calls = []
                    if hasattr(event, 'content') and event.content and hasattr(event.content, 'parts'):
                        for part in event.content.parts:
                            if hasattr(part, 'call') and part.call:
                                tool_calls.append({
                                    "tool": part.call.name,
                                    "args": part.call.args
                                })
                            elif hasattr(part, 'response') and part.response:
                                tool_calls.append({
                                    "tool_response": part.response.name,
                                    "result": part.response.result
                                })

                    # Convert model to dict and sanitize for GeoPoints/etc.
                    try:
                        event_dict = event.model_dump()
                        sanitized_event = sanitize_for_json(event_dict)
                        
                        # Humanize the action description for the Mobile UI
                        action_desc = "AI System Processing"
                        if tool_calls:
                            actions = []
                            for tc in tool_calls:
                                if "tool" in tc:
                                    name = tc['tool']
                                    if name == 'fuse_and_verify_signals': actions.append("Verifying incoming emergency signals")
                                    elif name == 'classify_and_predict': actions.append("Analyzing crisis severity and evolution")
                                    elif name == 'optimize_resources': actions.append("Optimizing resource allocation")
                                    elif name == 'simulate_and_report': actions.append("Generating response simulations")
                                    else: actions.append(f"Executing {name}")
                                
                                if "tool_response" in tc:
                                    name = tc['tool_response']
                                    if name == 'fuse_and_verify_signals': actions.append("Signals verified and merged")
                                    elif name == 'classify_and_predict': actions.append("Crisis classification complete")
                                    elif name == 'optimize_resources': actions.append("Resources dispatched")
                                    elif name == 'simulate_and_report': actions.append("Impact simulation ready")
                            
                            action_desc = " | ".join(actions)

                        tracer.log(
                            agent_name=event.author,
                            action=action_desc,
                            input_data={"tool_calls": tool_calls},
                            output_data=sanitized_event,
                            confidence=1.0
                        )
                    except Exception as e:
                        print(f"DEBUG: Error logging event: {e}")
                
                # Capture output from events
                if hasattr(event, 'content') and event.content:
                    if hasattr(event.content, 'parts'):
                        for part in event.content.parts:
                            if hasattr(part, 'text') and part.text:
                                final_output += part.text
                                
    except Exception as e:
        print(f"DEBUG: Exception during agent.run_async: {e}")
        raise e
    
    total_time = time.time() - start_run
    print(f"DEBUG: Pipeline finished in {total_time:.1f}s with {event_count} events.")
    return final_output
