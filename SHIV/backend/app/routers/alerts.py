from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
import urllib.parse
from ..database import get_db
from ..models import EscalationRequest, AlertLogDB

router = APIRouter(prefix="/alerts", tags=["Escalation & Alerts"])

@router.post("/escalate")
async def trigger_escalation(payload: EscalationRequest, db: AsyncSession = Depends(get_db)):
    # 1. Log alert event in DB
    log = AlertLogDB(
        device_id=payload.device_id or "default_wearable",
        contact_id=payload.contact_id,
        phone_number=payload.phone_number,
        channel=payload.channel,
        distress_score=payload.distress_score,
    )
    db.add(log)
    await db.commit()

    # 2. Generate deep links
    msg = (
        f"EmotiGuard Alert: Wearable detected sustained distress score ({payload.distress_score}/100). "
        "Reaching out for support."
    )
    encoded_msg = urllib.parse.quote(msg)

    whatsapp_link = f"whatsapp://send?phone={payload.phone_number}&text={encoded_msg}"
    sms_link = f"sms:{payload.phone_number}?body={encoded_msg}"

    return {
        "status": "escalation_registered",
        "contact_id": payload.contact_id,
        "phone_number": payload.phone_number,
        "channel": payload.channel,
        "distress_score": payload.distress_score,
        "deep_links": {
            "whatsapp": whatsapp_link,
            "sms": sms_link,
        },
        "helplines": {
            "india_tele_manas": "14416",
            "india_kiran": "1800-599-0019",
            "us_988": "988"
        }
    }
