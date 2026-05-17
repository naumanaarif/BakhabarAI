from google.adk.agents.invocation_context import InvocationContext
from google.adk.agents.run_config import RunConfig
from google.adk.sessions.session import Session
from google.adk.sessions.in_memory_session_service import InMemorySessionService
from google.adk.events.event import Event
from google.adk.utils.context_utils import Aclosing
from typing import AsyncGenerator
import uuid

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
    
    ctx = await create_root_context(agent)
    
    # Add user message to session
    user_event = Event(
        author="user",
        content=types.Content(role="user", parts=[types.Part(text=input_text)]),
        invocation_id=ctx.invocation_id
    )
    await ctx.session_service.append_event(ctx.session, user_event)
    
    # Log the user input to tracer
    tracer.log(
        agent_name="user",
        action="input_message",
        input_data={"text": input_text},
        output_data={},
        confidence=1.0
    )
    
    final_output = ""
    async with Aclosing(agent.run_async(ctx)) as agen:
        async for event in agen:
            # Log agent event to tracer
            if event.author != "user":
                tracer.log(
                    agent_name=event.author,
                    action="agent_response",
                    input_data={}, # In a real scenario, we might want to capture the prompt
                    output_data=event.model_dump(mode="json"),
                    confidence=1.0 # Could be extracted from model metadata if available
                )
            
            # Capture output from events
            if hasattr(event, 'content') and event.content:
                if hasattr(event.content, 'parts'):
                    for part in event.content.parts:
                        if hasattr(part, 'text') and part.text:
                            final_output += part.text
    
    return final_output
