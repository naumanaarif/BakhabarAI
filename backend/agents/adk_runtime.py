from google.adk.agents.invocation_context import InvocationContext
from google.adk.agents.run_config import RunConfig
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.adk.events.event import Event
from google.adk.utils.context_utils import Aclosing
import uuid
import os
import json
import asyncio
import time

# Import tracer at module level so it is always available
from tracer import tracer


async def create_root_context(agent) -> InvocationContext:
    """Creates a fresh invocation context for a single agent run."""
    session_service = InMemorySessionService()
    session_id = str(uuid.uuid4())
    app_name = "BakhabarAI"
    user_id = "anonymous"

    session = await session_service.get_session(
        app_name=app_name, user_id=user_id, session_id=session_id
    )
    if not session:
        session = await session_service.create_session(
            app_name=app_name, user_id=user_id, session_id=session_id
        )

    ctx = InvocationContext(
        invocation_id=str(uuid.uuid4()),
        session_service=session_service,
        session=session,
        agent=agent,
        branch="main",
        run_config=RunConfig(),
    )
    return ctx


def _clean_event_text(text: str) -> str:
    """Returns a human-readable summary of the agent event text."""
    import re
    text = text.strip()
    if not text:
        return ""
    if text.startswith("{") or "```json" in text:
        try:
            js = text.split("```json")[1].split("```")[0].strip() if "```json" in text else text
            data = json.loads(js)
            if isinstance(data, dict):
                for key in ("summary", "message", "description", "status", "report"):
                    if key in data and isinstance(data[key], str) and len(data[key]) > 2:
                        return data[key][:200]
                if "evaluations" in data:
                    return f"Evaluated {len(data['evaluations'])} signals."
                if "classifications" in data:
                    return f"Classified {len(data['classifications'])} incidents."
            return "Committed structured data to database."
        except Exception:
            pass
    cleaned = re.sub(r"[\*\#_`\-]", "", text)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned[:200] if cleaned else "Processing…"


async def _consume_agent_events(agent, ctx) -> str:
    """
    Streams events from a running agent until a terminal condition or tool cap.
    - Breaks immediately after the FIRST tool response (all our tools are single-call).
    - Caps at MAX_EVENTS total events to prevent infinite loops on text-only LLM replies.
    Returns final text output.
    """
    out = ""
    tool_count = 0
    MAX_TOOLS = 3
    MAX_EVENTS = 30           # Hard cap — prevents infinite event streams
    MAX_TEXT_ONLY = 6         # Break if LLM keeps chatting without calling a tool
    event_count = 0
    text_only_events = 0
    seen_hashes: set = set()
    got_tool_response = False

    print(f"[ADK] ▶ Starting event stream for: {agent.name}")

    async with Aclosing(agent.run_async(ctx)) as agen:
        try:
            async for event in agen:
                event_count += 1
                if event.author == "user":
                    continue

                event_text = ""
                tool_info = []
                terminal = False
                has_tool_part = False

                if hasattr(event, "content") and event.content and hasattr(event.content, "parts"):
                    for part in event.content.parts:
                        if hasattr(part, "call") and part.call:
                            h = f"{part.call.name}:{json.dumps(part.call.args, sort_keys=True, default=str)}"
                            if h not in seen_hashes:
                                seen_hashes.add(h)
                                tool_count += 1
                                has_tool_part = True
                                tool_info.append(f"Calling: {part.call.name}")
                                print(f"[ADK]   🔧 [{agent.name}] Tool call #{tool_count}: {part.call.name}")
                        elif hasattr(part, "response") and part.response:
                            got_tool_response = True
                            terminal = True
                            has_tool_part = True
                            tool_info.append(f"Completed: {part.response.name}")
                            print(f"[ADK]   ✅ [{agent.name}] Tool response received: {part.response.name}")
                        elif hasattr(part, "text") and part.text:
                            event_text += part.text
                            out += part.text
                            print(f"[ADK]   💬 [{agent.name}] Text event #{event_count}: {part.text[:120].strip()!r}")

                if not has_tool_part and event_text:
                    text_only_events += 1
                    print(f"[ADK]   📝 [{agent.name}] Text-only event {text_only_events}/{MAX_TEXT_ONLY}")

                # Build a meaningful, concise tracer entry
                action = _clean_event_text(event_text)
                if not action and tool_info:
                    action = " | ".join(tool_info)
                if terminal or got_tool_response:
                    action = "Task complete -- results committed to database."
                if not action:
                    action = "AI reasoning..."

                # Always log
                try:
                    tracer.log(
                        agent_name=event.author,
                        action=action,
                        input_data={"tools": tool_info},
                        output_data={},
                        confidence=1.0,
                    )
                except Exception as log_err:
                    print(f"[ADK] Tracer write error: {log_err}")

                # ── Exit conditions ─────────────────────────────────────────
                if got_tool_response:
                    print(f"[ADK] ✔ [{agent.name}] Tool response received — exiting stream.")
                    break
                if tool_count >= MAX_TOOLS:
                    print(f"[ADK] ⚠ [{agent.name}] Tool cap reached ({MAX_TOOLS}) — exiting stream.")
                    break
                if text_only_events >= MAX_TEXT_ONLY:
                    print(f"[ADK] ⚠ [{agent.name}] Text-only cap reached ({MAX_TEXT_ONLY}) — LLM not calling tools, exiting.")
                    tracer.log(agent_name=agent.name, action="Warning: Agent produced text without calling tool — forcing exit.", input_data={}, output_data={}, confidence=0.5)
                    break
                if event_count >= MAX_EVENTS:
                    print(f"[ADK] ⚠ [{agent.name}] Max event cap reached ({MAX_EVENTS}) — forcing exit.")
                    tracer.log(agent_name=agent.name, action="Warning: Max event limit hit — forced exit.", input_data={}, output_data={}, confidence=0.5)
                    break

        except asyncio.CancelledError:
            print(f"[ADK] ❌ [{agent.name}] Cancelled inside event loop.")

    print(f"[ADK] ◀ Stream ended for {agent.name}: events={event_count}, tools={tool_count}, tool_response={got_tool_response}")
    return out


async def run_agent_standalone(agent, input_text: str) -> str:
    """
    Runs a single ADK agent, with retry + Gemini fallback on rate limits.
    All agent events are logged to the global tracer for the /api/logs endpoint.
    """
    from google.genai import types

    print(f"[ADK] >> Running: {agent.name}")
    from .model_config import set_key_for_agent
    set_key_for_agent(agent.name)

    MAX_RETRIES = 3
    retry_delay = 8   # Start with 8s to give Gemini quota time to reset

    for attempt in range(MAX_RETRIES):
        from .model_config import get_model
        agent.model = get_model(agent.name, force_gemini=(attempt >= 2))

        ctx = await create_root_context(agent)

        if attempt == 0:
            display = input_text[:117] + "..." if len(input_text) > 120 else input_text
            tracer.log(
                agent_name=agent.name,
                action=f"Starting task: {display}",
                input_data={},
                output_data={},
                confidence=1.0,
            )

        user_event = Event(
            author="user",
            content=types.Content(role="user", parts=[types.Part(text=input_text)]),
            invocation_id=ctx.invocation_id,
        )
        await ctx.session_service.append_event(ctx.session, user_event)

        t0 = time.time()
        try:
            final_output = await asyncio.wait_for(
                _consume_agent_events(agent, ctx),
                timeout=60.0,
            )
            elapsed = time.time() - t0
            print(f"[ADK] OK {agent.name} finished in {elapsed:.1f}s (attempt {attempt + 1})")
            tracer.log(
                agent_name=agent.name,
                action=f"Agent completed in {elapsed:.1f}s.",
                input_data={},
                output_data={},
                confidence=1.0,
            )
            return final_output

        except asyncio.TimeoutError:
            print(f"[ADK] TIMEOUT {agent.name} (attempt {attempt + 1})")
            tracer.log(agent_name=agent.name, action=f"Timeout on attempt {attempt + 1} -- retrying...", input_data={}, output_data={}, confidence=0.3)
            if attempt < MAX_RETRIES - 1:
                from .model_config import rotate_groq_key
                rotate_groq_key(agent.name)
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 30)
                continue
            raise Exception(f"{agent.name} timed out after {MAX_RETRIES} attempts.")

        except asyncio.CancelledError:
            print(f"[ADK] CANCELLED {agent.name} (attempt {attempt + 1})")
            tracer.log(agent_name=agent.name, action=f"Cancelled on attempt {attempt + 1} -- retrying...", input_data={}, output_data={}, confidence=0.3)
            if attempt < MAX_RETRIES - 1:
                from .model_config import rotate_groq_key
                rotate_groq_key(agent.name)
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 30)
                continue
            raise Exception(f"{agent.name} repeatedly cancelled.")

        except Exception as e:
            err = str(e)
            is_rate_limit = "rate_limit" in err.lower() or "429" in err or "quota" in err.lower()
            if is_rate_limit:
                print(f"[ADK] RATE LIMIT on attempt {attempt + 1}. Waiting {retry_delay}s...")
                tracer.log(agent_name=agent.name, action=f"Rate limit -- rotating key, waiting {retry_delay}s", input_data={}, output_data={}, confidence=0.2)
                from .model_config import rotate_groq_key
                rotate_groq_key(agent.name)
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 60)
            else:
                print(f"[ADK] ❌ ERROR in {agent.name} (attempt {attempt+1}): {type(e).__name__}: {e}")
                tracer.log(agent_name=agent.name, action=f"Error ({type(e).__name__}): {str(e)[:200]}", input_data={}, output_data={}, confidence=0.0)
                raise

    raise Exception(f"{agent.name} failed after {MAX_RETRIES} attempts.")
