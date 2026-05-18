import asyncio
import sys
import os
import time

# Add backend root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.pipeline import run_crisis_simulation
from agents.model_config import get_model

async def main():
    model = get_model()
    model_name = getattr(model, 'model', 'Unknown')
    print(f"🚀 Triggering Agent Pipeline ({model_name})...")
    print("Detecting and processing pending signals in Firestore...")
    
    start_time = time.time()
    try:
        # Trigger the full ADK pipeline
        result = await run_crisis_simulation()
        
        print("\n✅ Pipeline Execution Complete!")
        print(f"Time elapsed: {int(time.time() - start_time)} seconds")
        print("--- Pipeline Summary ---")
        print(result)
        print("------------------------")
        print("\nCheck your Mobile App 'Agent Logs' and 'Incidents' screen to see the results!")
        
    except Exception as e:
        print("\n❌ Pipeline Interrupted!")
        if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
            print("\n⚠️  QUOTA LIMIT REACHED (429):")
            print("Even with a paid plan, Google sometimes routes requests to the free tier if the project isn't correctly set up in Google AI Studio.")
            print("\n💡 ACTION: Please ensure your API Key is from a project with billing enabled.")
        else:
            print(f"Error details: {e}")

if __name__ == "__main__":
    asyncio.run(main())
