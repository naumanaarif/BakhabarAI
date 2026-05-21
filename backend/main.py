import sys
import os

# Force unbuffered output so print() is immediately visible in uvicorn console
os.environ["PYTHONUNBUFFERED"] = "1"
import builtins
_orig_print = builtins.print
def _print_flush(*args, **kwargs):
    kwargs.setdefault("flush", True)
    _orig_print(*args, **kwargs)
builtins.print = _print_flush

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
    import sys
    banner = [
        "",
        "="*60,
        "\U0001f680 BakhabarAI Backend Started",
        "   \u25ba GET  /api/incidents        -- active incidents",
        "   \u25ba POST /api/run-scenario     -- trigger agent pipeline",
        "   \u25ba GET  /api/logs             -- agent trace logs",
        "   \u25ba GET  /api/debug/ping       -- health check",
        "   \u25ba DEL  /api/debug/logs       -- clear in-memory logs",
        "="*60,
        "",
    ]
    for line in banner:
        print(line, flush=True)
        sys.stdout.flush()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
