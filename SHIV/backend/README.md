# EmotiGuard Backend Server (FastAPI + WebSocket)

Real-time backend server providing time-series biometric persistence, server-side distress evaluation, 48-hour trend tracking, escalation alerts, and live WebSockets.

## Requirements
- Python 3.10+
- Dependencies in `requirements.txt`

## Installation & Running

1. Open a terminal in the `backend` directory:
   ```bash
   cd backend
   ```

2. (Optional) Create and activate a virtual environment:
   ```bash
   python -m venv venv
   # On Windows:
   .\venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Launch the FastAPI server:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

5. Explore the interactive API Documentation (Swagger UI):
   - Navigate to: **`http://localhost:8000/docs`**

## Key Endpoints

- `POST /api/v1/sensor/packet`: Ingest single 5-second biophysical packet; evaluates distress and broadcasts to live WebSockets.
- `POST /api/v1/sensor/batch`: Batch upload offline packets from mobile client.
- `GET /api/v1/sensor/history`: Query historical readings for 1h / 24h / 7d trends.
- `GET /api/v1/baseline/{device_id}`: Retrieve learned 7-day baseline parameters.
- `GET /api/v1/baseline/{device_id}/trend48h`: Run 48-hour gradual stress drift analysis.
- `POST /api/v1/alerts/escalate`: Register escalation event and generate SMS / WhatsApp deep links.
- `WS /ws/live`: Real-time bidirectional WebSocket stream for live monitor dashboards.
