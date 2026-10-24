import math
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from ..database import get_db
from ..models import SensorPacketIn, DistressAssessmentOut, SensorBatchUpload, SensorReadingDB, BaselineDB
from ..scoring import ServerDistressEngine
from ..websocket_manager import ws_manager

router = APIRouter(prefix="/sensor", tags=["Sensor Stream"])

@router.post("/packet", response_model=DistressAssessmentOut)
async def ingest_packet(packet: SensorPacketIn, db: AsyncSession = Depends(get_db)):
    # 1. Fetch user baseline (or default)
    q = select(BaselineDB).where(BaselineDB.device_id == packet.device_id)
    res = await db.execute(q)
    baseline_record = res.scalars().first()

    baseline_dict = {
        "mean_hr": baseline_record.mean_hr if baseline_record else 72.0,
        "std_hr": baseline_record.std_hr if baseline_record else 8.5,
        "mean_eda": baseline_record.mean_eda if baseline_record else 2.2,
        "std_eda": baseline_record.std_eda if baseline_record else 0.7,
        "mean_hrv": baseline_record.mean_hrv if baseline_record else 52.0,
        "std_hrv": baseline_record.std_hrv if baseline_record else 14.0,
    }

    # 2. Evaluate distress score
    distress = ServerDistressEngine.calculate_score(packet, baseline_dict)

    # 3. Store in DB
    db_entry = SensorReadingDB(
        user_id=packet.user_id,
        device_id=packet.device_id,
        timestamp=packet.ts,
        heart_rate=packet.hr,
        hrv=packet.hrv,
        eda=packet.eda,
        accel_x=packet.accel.x,
        accel_y=packet.accel.y,
        accel_z=packet.accel.z,
        distress_score=distress["score"],
    )
    db.add(db_entry)
    await db.commit()

    # 4. Broadcast to live WebSockets
    await ws_manager.broadcast_packet({
        "type": "live_sensor_packet",
        "user_id": packet.user_id,
        "device_id": packet.device_id,
        "packet": packet.model_dump(),
        "distress": distress,
    })

    return DistressAssessmentOut(**distress)

@router.post("/batch")
async def batch_sync(upload: SensorBatchUpload, db: AsyncSession = Depends(get_db)):
    # Batch sync for offline cache upload (when user opted in)
    records = []
    for p in upload.packets:
        records.append(
            SensorReadingDB(
                device_id=upload.device_id,
                timestamp=p.ts,
                heart_rate=p.hr,
                hrv=p.hrv,
                eda=p.eda,
                accel_x=p.accel.x,
                accel_y=p.accel.y,
                accel_z=p.accel.z,
                distress_score=None,
            )
        )
    db.add_all(records)
    await db.commit()
    return {"status": "success", "synced_count": len(records)}

@router.get("/history")
async def get_history(
    device_id: Optional[str] = None,
    user_id: Optional[int] = None,
    limit: int = Query(60, le=500),
    db: AsyncSession = Depends(get_db),
):
    q = select(SensorReadingDB)
    if user_id is not None:
        q = q.where(SensorReadingDB.user_id == user_id)
    elif device_id is not None:
        q = q.where(SensorReadingDB.device_id == device_id)
    else:
        q = q.where(SensorReadingDB.device_id == "default_wearable")

    q = q.order_by(desc(SensorReadingDB.timestamp)).limit(limit)
    res = await db.execute(q)
    rows = res.scalars().all()
    # Reverse to return chronological order
    return [
        {
            "ts": r.timestamp,
            "hr": r.heart_rate,
            "hrv": r.hrv,
            "eda": r.eda,
            "accel": {"x": r.accel_x, "y": r.accel_y, "z": r.accel_z},
            "distress_score": r.distress_score,
            "user_id": r.user_id,
            "device_id": r.device_id,
        }
        for r in reversed(rows)
    ]
