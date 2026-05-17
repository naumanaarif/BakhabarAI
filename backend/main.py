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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
