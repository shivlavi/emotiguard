/**
 * EmotiGuard System Configuration
 * Defines BLE UUIDs, physiological normal ranges, and system constants.
 */

export const APP_CONFIG = {
  APP_NAME: 'EmotiGuard',
  VERSION: '1.0.0',
  ACADEMIC_DISCLAIMER: `EMOTIGUARD RESEARCH NOTICE: This application is an educational prototype developed for IoT and physiological signal telemetry. Physiological trend visualizations (such as autonomic arousal indicators) reflect exploratory autonomous nervous system metrics and MUST NOT be used for medical diagnosis, clinical decision-making, or psychological assessment.`,
  PARTICIPANT_PRIVACY_NOTICE: `Participant IDs are used locally for data separation and session tagging. They do NOT provide authenticated access control or HIPAA/GDPR clinical compliance.`,
  
  // Bluetooth Low Energy Specifications
  BLE: {
    DEVICE_NAME_PREFIX: 'EmotiGuard',
    
    // Standard Bluetooth SIG Heart Rate Service (for off-the-shelf HR straps or standard ESP32 libraries)
    STANDARD_HR_SERVICE_UUID: 0x180D,
    STANDARD_HR_CHAR_UUID: 0x2A37,
    
    // EmotiGuard Custom Multi-Sensor GATT Service (streams HR, HRV, SpO2, GSR in single packet or JSON)
    CUSTOM_SERVICE_UUID: '0000ffe0-0000-1000-8000-00805f9b34fb',
    CUSTOM_DATA_CHAR_UUID: '0000ffe1-0000-1000-8000-00805f9b34fb',
    CUSTOM_CMD_CHAR_UUID: '0000ffe2-0000-1000-8000-00805f9b34fb',

    // Fallback standard battery service
    BATTERY_SERVICE_UUID: 0x180F,
    BATTERY_LEVEL_CHAR_UUID: 0x2A19,
  },

  // Physiological Sensor Parameter Definitions & Baseline Thresholds
  SENSORS: {
    HEART_RATE: {
      id: 'hr',
      name: 'Heart Rate',
      unit: 'BPM',
      min: 40,
      max: 180,
      normalMin: 60,
      normalMax: 100,
      color: '#F43F5E', // Rose/Red
      accentColor: '#FB7185',
      icon: 'heart-pulse',
      description: 'Cardiac pulse frequency measured in beats per minute.'
    },
    HRV_RMSSD: {
      id: 'hrv',
      name: 'Heart Rate Variability',
      subtext: 'RMSSD',
      unit: 'ms',
      min: 5,
      max: 150,
      normalMin: 25,
      normalMax: 75,
      color: '#A855F7', // Violet
      accentColor: '#C084FC',
      icon: 'activity',
      description: 'Root Mean Square of Successive Differences between R-R intervals; reflects parasympathetic vagal tone.'
    },
    SPO2: {
      id: 'spo2',
      name: 'Blood Oxygen',
      subtext: 'SpO₂',
      unit: '%',
      min: 80,
      max: 100,
      normalMin: 95,
      normalMax: 100,
      color: '#06B6D4', // Cyan
      accentColor: '#22D3EE',
      icon: 'droplets',
      description: 'Peripheral capillary oxygen saturation estimated via photoplethysmography (PPG).'
    },
    GSR: {
      id: 'gsr',
      name: 'Skin Conductance',
      subtext: 'EDA / GSR',
      unit: 'µS',
      min: 0.2,
      max: 30.0,
      normalMin: 1.5,
      normalMax: 15.0,
      color: '#3B82F6', // Blue
      accentColor: '#60A5FA',
      icon: 'zap',
      description: 'Electrodermal activity reflecting sympathetic sweat gland innervation.'
    }
  },

  // Sampling & Display Settings
  STREAMING: {
    SAMPLE_INTERVAL_MS: 1000,   // 1 Hz telemetric update interval
    MAX_LIVE_POINTS: 60,        // 60 seconds rolling window for live dashboard
    MAX_SESSION_POINTS: 18000,  // Max 5 hours at 1Hz in memory
  },

  STORAGE_KEYS: {
    PARTICIPANTS: 'emotiguard_participants_v1',
    ACTIVE_PARTICIPANT: 'emotiguard_active_participant_v1',
    SESSIONS: 'emotiguard_sessions_v1',
    APP_SETTINGS: 'emotiguard_settings_v1'
  }
};
