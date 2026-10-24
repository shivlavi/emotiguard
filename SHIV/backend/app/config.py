import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "EmotiGuard Backend API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./emotiguard_server.db")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "emotiguard_super_secret_jwt_key_2026")
    
    # Distress Thresholds
    CALM_SCORE_MAX: float = 30.0
    MILD_SCORE_MAX: float = 55.0
    ELEVATED_SCORE_MAX: float = 80.0

settings = Settings()
