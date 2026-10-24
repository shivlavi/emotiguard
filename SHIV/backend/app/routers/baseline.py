import math
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from ..database import get_db
from ..models import BaselineDB, SensorReadingDB, BaselineProfileOut
from ..scoring import ServerDistressEngine

router = APIRouter(prefix="/baseline", tags=["Baseline & Trends"])

@router.get("/{device_id}", response_model=BaselineProfileOut)
async def get_user_baseline(device_id: str, db: AsyncSession = Depends(get_db)):
    q = select(BaselineDB).where(BaselineDB.device_id == device_id)
    res = await db.execute(q)
    baseline = res.scalars().first()

    if not baseline:
        return BaselineProfileOut(
            device_id=device_id,
            mean_hr=72.0,
            std_hr=8.5,
            mean_eda=2.2,
            std_eda=0.7,
            mean_hrv=52.0,
            std_hrv=14.0,
            days_calibrated=1,
            is_calibrated=False,
        )

    return BaselineProfileOut(
        device_id=device_id,
        mean_hr=baseline.mean_hr,
        std_hr=baseline.std_hr,
        mean_eda=baseline.mean_eda,
        std_eda=baseline.std_eda,
        mean_hrv=baseline.mean_hrv,
        std_hrv=baseline.std_hrv,
        days_calibrated=baseline.days_calibrated,
        is_calibrated=baseline.days_calibrated >= 7,
    )

@router.get("/{device_id}/trend48h")
async def evaluate_48h_trend(device_id: str, db: AsyncSession = Depends(get_db)):
    # Fetch recent readings for 48h trend
    q = (
        select(SensorReadingDB)
        .where(SensorReadingDB.device_id == device_id)
        .order_by(desc(SensorReadingDB.timestamp))
        .limit(200)
    )
    res = await db.execute(q)
    rows = res.scalars().all()

    # Baseline
    b_q = select(BaselineDB).where(BaselineDB.device_id == device_id)
    b_res = await db.execute(b_q)
    b = b_res.scalars().first()

    baseline_dict = {
        "mean_hr": b.mean_hr if b else 72.0,
        "std_hr": b.std_hr if b else 8.5,
        "mean_eda": b.mean_eda if b else 2.2,
        "std_eda": b.std_eda if b else 0.7,
    }

    history = [
        {
            "hr": r.heart_rate,
            "eda": r.eda,
            "movement": abs(math.sqrt(r.accel_x**2 + r.accel_y**2 + r.accel_z**2) - 1.0)
        }
        for r in rows
    ]

    result = ServerDistressEngine.detect_48h_gradual_worsening(history, baseline_dict)
    return {
        "device_id": device_id,
        "samples_analyzed": len(rows),
        **result
    }
