import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

def initialize_firebase():
    """
    Initializes Firebase Admin SDK.
    Uses service account from FIREBASE_SERVICE_ACCOUNT_PATH or falls back to default credentials.
    """
    if not firebase_admin._apps:
        cred_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        project_id = os.getenv("FIREBASE_PROJECT_ID", "fleet-rite-496215-n7")
        
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred, {
                'projectId': project_id,
            })
        else:
            # Fallback to default credentials
            firebase_admin.initialize_app(options={
                'projectId': project_id,
            })
    
    # Explicitly use the 'bakhabarai-db' database
    return firestore.client(database_id="bakhabarai-db")

# Singleton db instance
db = initialize_firebase()
