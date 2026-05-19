import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import mock_data_router
import config

app = FastAPI(
    title="BakhabarAI Backend",
    description="Backend API for BakhabarAI Flutter App",
    version="1.0.0"
)

# Allow CORS for mobile app and local dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the mock data router
app.include_router(mock_data_router.router)

@app.get("/")
async def root():
    return {"message": "Welcome to BakhabarAI API"}

@app.on_event("startup")
async def startup_event():
    print("\n" + "="*60)
    print("🚀 BakhabarAI Backend Started")
    print("   ► GET  /api/incidents        — active incidents")
    print("   ► POST /api/run-scenario     — trigger agent pipeline")
    print("   ► GET  /api/logs             — agent trace logs")
    print("   ► GET  /api/debug/ping       — health check")
    print("   ► DEL  /api/debug/logs       — clear in-memory logs")
    print("="*60 + "\n")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
