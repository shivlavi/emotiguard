from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field
from sqlalchemy import Column, Integer, Float, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import declarative_base

Base = declarative_base()

# ============================================================================
# SQLAlchemy Database Models
# ============================================================================

class UserDB(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String(128), unique=True, index=True, nullable=False)
    hashed_password = Column(String(128), nullable=False)
    full_name = Column(String(64), nullable=False)
    device_id = Column(String(64), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class SensorReadingDB(Base):
    __tablename__ = "sensor_readings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    device_id = Column(String(64), index=True, default="default_wearable")
    timestamp = Column(Integer, index=True)
    heart_rate = Column(Float, nullable=False)
    hrv = Column(Float, nullable=False)
    eda = Column(Float, nullable=False)
    accel_x = Column(Float, nullable=False)
    accel_y = Column(Float, nullable=False)
    accel_z = Column(Float, nullable=False)
    distress_score = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class BaselineDB(Base):
    __tablename__ = "user_baselines"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    device_id = Column(String(64), unique=True, index=True)
    mean_hr = Column(Float, default=72.0)
    std_hr = Column(Float, default=8.5)
    mean_eda = Column(Float, default=2.2)
    std_eda = Column(Float, default=0.7)
    mean_hrv = Column(Float, default=52.0)
    std_hrv = Column(Float, default=14.0)
    days_calibrated = Column(Integer, default=1)
    updated_at = Column(DateTime, default=datetime.utcnow)

class AlertLogDB(Base):
    __tablename__ = "alert_logs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    device_id = Column(String(64), index=True)
    contact_id = Column(String(64))
    phone_number = Column(String(32))
    channel = Column(String(16)) # 'sms' or 'whatsapp'
    distress_score = Column(Float)
    timestamp = Column(DateTime, default=datetime.utcnow)

# ============================================================================
# Pydantic Request / Response Schemas
# ============================================================================

class UserRegister(BaseModel):
    email: str
    password: str
    full_name: str
    device_id: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

class UserProfileOut(BaseModel):
    id: int
    email: str
    full_name: str
    device_id: str
    created_at: datetime

class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfileOut

class OtpSendRequest(BaseModel):
    contact: str
    channel: str = "email" # 'email' or 'sms'
    purpose: str = "login"

class OtpSendResponse(BaseModel):
    success: bool
    message: str
    contact: str
    channel: str
    expires_in: int = 300
    demo_code: Optional[str] = None

class OtpVerifyRequest(BaseModel):
    contact: str
    code: str
    channel: Optional[str] = "email"
    password: Optional[str] = None

class OtpVerifyResponse(BaseModel):
    verified: bool
    message: str
    access_token: Optional[str] = None
    user: Optional[UserProfileOut] = None

class AccelVector(BaseModel):
    x: float
    y: float
    z: float

class SensorPacketIn(BaseModel):
    ts: int = Field(..., description="UNIX timestamp in seconds")
    hr: float = Field(..., description="Heart rate in BPM")
    hrv: float = Field(..., description="HRV RMSSD in milliseconds")
    eda: float = Field(..., description="Electrodermal activity in microSiemens")
    accel: AccelVector
    cs: Optional[int] = Field(None, description="Integrity checksum")
    device_id: Optional[str] = "default_wearable"
    user_id: Optional[int] = None

class DistressAssessmentOut(BaseModel):
    score: float
    level: str
    friendly_summary: str
    hr_z_score: float
    eda_z_score: float
    hrv_z_score: float
    is_active: bool

class SensorBatchUpload(BaseModel):
    device_id: str
    packets: List[SensorPacketIn]

class BaselineProfileOut(BaseModel):
    device_id: str
    mean_hr: float
    std_hr: float
    mean_eda: float
    std_eda: float
    mean_hrv: float
    std_hrv: float
    days_calibrated: int
    is_calibrated: bool

class EscalationRequest(BaseModel):
    contact_id: str
    phone_number: str
    distress_score: float
    channel: str = "sms" # 'sms' or 'whatsapp'
    device_id: Optional[str] = "default_wearable"
