import math
from typing import Dict, Any, List
from .models import SensorPacketIn, BaselineProfileOut

class ServerDistressEngine:
    @staticmethod
    def calculate_score(packet: SensorPacketIn, baseline: Dict[str, float]) -> Dict[str, Any]:
        mean_hr = baseline.get("mean_hr", 72.0)
        std_hr = baseline.get("std_hr", 8.5)
        mean_eda = baseline.get("mean_eda", 2.2)
        std_eda = baseline.get("std_eda", 0.7)
        mean_hrv = baseline.get("mean_hrv", 52.0)
        std_hrv = baseline.get("std_hrv", 14.0)

        # 1. Z-Scores
        z_hr = (packet.hr - mean_hr) / (std_hr if std_hr > 0 else 8.0)
        z_eda = (packet.eda - mean_eda) / (std_eda if std_eda > 0 else 0.7)
        z_hrv = (mean_hrv - packet.hrv) / (std_hrv if std_hrv > 0 else 14.0)

        # 2. Sigmoid scaling
        def sigmoid(z: float) -> float:
            clamped = max(-3.0, min(4.0, z))
            return 100.0 / (1.0 + math.exp(-1.1 * (clamped - 0.5)))

        score_hr = sigmoid(z_hr)
        score_eda = sigmoid(z_eda)
        score_hrv = sigmoid(z_hrv)

        # 3. Movement dampener
        raw_mag = math.sqrt(packet.accel.x**2 + packet.accel.y**2 + packet.accel.z**2)
        movement = abs(raw_mag - 1.0)
        is_active = movement > 0.25

        dampener = 1.0
        if is_active:
            dampener = max(0.20, 1.0 - (movement - 0.25) * 1.5)

        # 4. Composite
        composite = (score_hr * 0.35) + (score_eda * 0.40) + (score_hrv * 0.25)
        final_score = round(max(5.0, min(100.0, composite * dampener)), 1)

        # 5. Level determination
        if final_score < 30.0:
            level = "calm"
            summary = "Vitals are relaxed and steady within your baseline zone."
        elif final_score < 55.0:
            level = "mild"
            summary = "Slight physiological arousal detected. A gentle pause is recommended."
        elif final_score < 80.0:
            level = "elevated"
            summary = "Heightened stress detected while stationary. Suggested 4-7-8 breathing."
        else:
            level = "acute"
            summary = "Sustained sympathetic activation. Reaching out to a trusted contact is suggested."

        if is_active:
            summary = "Physical movement detected. Elevated vitals reflect healthy physical exertion."

        return {
            "score": final_score,
            "level": level,
            "friendly_summary": summary,
            "hr_z_score": round(z_hr, 2),
            "eda_z_score": round(z_eda, 2),
            "hrv_z_score": round(z_hrv, 2),
            "is_active": is_active,
        }

    @staticmethod
    def detect_48h_gradual_worsening(history: List[Dict[str, float]], baseline: Dict[str, float]) -> Dict[str, Any]:
        if len(history) < 20:
            return {
                "worsening": False,
                "summary": "Collecting baseline data for 48h trend detection.",
                "mean_deviation": 0.0
            }

        # Filter out high movement samples
        resting = [h for h in history if h.get("movement", 0.0) < 0.25]
        if not resting:
            return {"worsening": False, "summary": "Normal baseline activity.", "mean_deviation": 0.0}

        avg_hr = sum(h["hr"] for h in resting) / len(resting)
        avg_eda = sum(h["eda"] for h in resting) / len(resting)

        hr_z = (avg_hr - baseline.get("mean_hr", 72.0)) / baseline.get("std_hr", 8.5)
        eda_z = (avg_eda - baseline.get("mean_eda", 2.2)) / baseline.get("std_eda", 0.7)

        worsening = (hr_z >= 1.15) and (eda_z >= 1.30)
        summary = (
            f"Sustained 48h elevation detected: HR +{round(avg_hr - baseline.get('mean_hr', 72), 1)} bpm, "
            f"EDA +{round(avg_eda - baseline.get('mean_eda', 2.2), 1)} uS."
            if worsening else "48-hour vitals remain comfortably aligned with resting baseline."
        )

        return {
            "worsening": worsening,
            "summary": summary,
            "mean_deviation": round((hr_z + eda_z) / 2.0, 2)
        }
