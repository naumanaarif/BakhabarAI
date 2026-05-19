import asyncio
import sys
import os

# Add backend root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from firebase_config import db

async def clear_stale_data():
    """
    Clears all signals and incidents from Firestore to allow a fresh start.
    Useful when the database is cluttered with mock signals or failed processing attempts.
    """
    print("🚀 [CLEANUP] Starting database cleanup...")
    
    collections = ["signals", "incidents", "agent_logs", "action_simulations"]
    
    for coll_name in collections:
        print(f"DEBUG: Clearing collection '{coll_name}'...")
        docs = db.collection(coll_name).get()
        count = 0
        for doc in docs:
            doc.reference.delete()
            count += 1
        print(f"✅ [CLEANUP] Deleted {count} documents from '{coll_name}'.")

    print("\n✨ Database is now clean. Future reports will not trigger old incidents.")

if __name__ == "__main__":
    asyncio.run(clear_stale_data())
