import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from .config import settings
from .database import init_db
from .routers import sensor, baseline, alerts, auth
from .websocket_manager import ws_manager

STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize database tables
    await init_db()
    print("[EmotiGuard Backend] Database initialized with Auth & User Isolation.")
    yield
    # Shutdown
    print("[EmotiGuard Backend] Shutting down.")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="IoT Emotional Distress Detection & Support System - Real-time Server with User Isolation",
    lifespan=lifespan,
)

# Enable CORS for Flutter mobile apps & web dashboards
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include REST Routers
app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(sensor.router, prefix=settings.API_V1_STR)
app.include_router(baseline.router, prefix=settings.API_V1_STR)
app.include_router(alerts.router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "healthy",
        "docs_url": "/docs",
        "demo_dashboard_url": "/demo",
    }

@app.get("/login")
@app.get("/demo")
@app.get("/dashboard")
async def demo_page():
    html_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(html_file):
        return FileResponse(html_file)
    return {"error": "Dashboard template not found"}

@app.websocket("/ws/live")
async def websocket_live_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            # Receive client ping or relay payload
            data = await websocket.receive_json()
            if data.get("type") == "sensor_relay":
                # Broadcast relayed packet to all connected listeners
                await ws_manager.broadcast_packet({
                    "type": "relayed_sensor_packet",
                    "payload": data
                })
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=port, reload=False)

