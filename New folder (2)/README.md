# 🛡️ EmotiGuard — Wearable Physiological IoT Telemetry Dashboard

[![Project](https://img.shields.io/badge/Project-College%20IoT%20Capstone-blue.svg)](file:///c:/Users/palj2/OneDrive/Desktop/New%20folder%20%282%29/README.md)
[![Status](https://img.shields.io/badge/Version-1.0.0--v1-cyan.svg)](file:///c:/Users/palj2/OneDrive/Desktop/New%20folder%20%282%29/README.md)
[![Stack](https://img.shields.io/badge/Frontend-ES6%20Modules%20%2B%20Tailwind%20%2B%20Chart.js-violet.svg)](file:///c:/Users/palj2/OneDrive/Desktop/New%20folder%20%282%29/README.md)
[![Hardware](https://img.shields.io/badge/Hardware-ESP32%20BLE%20GATT-emerald.svg)](file:///c:/Users/palj2/OneDrive/Desktop/New%20folder%20%282%29/README.md)

**EmotiGuard** is a modern, responsive web application designed for a college IoT project. It collects, visualizes, and records real-time physiological telemetry streamed from an ESP32-based wearable device over **Bluetooth Low Energy (BLE)** via the standard **Web Bluetooth API**.

---

## 📑 Table of Contents
1. [Key Features (Version 1)](#-key-features-version-1)
2. [Design & UI Architecture](#-design--ui-architecture)
3. [Quick Start & Local Launch](#-quick-start--local-launch)
4. [System Architecture](#-system-architecture)
5. [Sensor Specifications & Physiological Metrics](#-sensor-specifications--physiological-metrics)
6. [Web Bluetooth API & GATT Specifications](#-web-bluetooth-api--gatt-specifications)
7. [ESP32 Hardware Wiring & Firmware](#-esp32-hardware-wiring--firmware)
8. [Session Recording & CSV Export](#-session-recording--csv-export)
9. [Participant Profiles & Data Separation](#-participant-profiles--data-separation)
10. [Phase 2 Roadmap: Firebase Auth & Firestore](#-phase-2-roadmap-firebase-auth--firestore)
11. [Academic & Research Disclaimers](#-academic--research-disclaimers)

---

## 🌟 Key Features (Version 1)

* **Four Real-Time Physiological Sensor Cards**:
  * **Heart Rate (BPM)**: Continuous cardiac pulse with live pulsating beat animation and session min/max/average.
  * **Heart Rate Variability (HRV RMSSD in ms)**: Root Mean Square of Successive Differences; index of parasympathetic vagal activity.
  * **Blood Oxygen Saturation (SpO₂ %)**: Peripheral capillary saturation estimated via photoplethysmography.
  * **Skin Conductance (EDA / GSR in µS)**: Electrodermal activity reflecting sympathetic nervous system sweat gland innervation.
* **Full-Fidelity Demo Mode**:
  * Synthetic biological telemetry generator simulating respiratory sinus arrhythmia (RSA), Mayer vasomotor waves, and tonic/phasic electrodermal responses.
  * Clearly identified with a persistent, unmissable amber warning banner.
  * Includes a **"Trigger Sympathetic Stress Spike"** button to immediately observe dynamic physiological responses in charts and indicators without needing physical sensors.
* **Native Web Bluetooth (BLE) Connection**:
  * Connects directly from Google Chrome / Microsoft Edge to the ESP32 without native desktop drivers or plugins.
  * Live GATT diagnostics console displaying real-time connection lifecycle and packet logs.
  * Graceful error handling for pairing cancellations, disabled Bluetooth, and connection drops.
* **Session Lifecycle Controls**:
  * **Start**, **Pause**, and **Stop & Save** session recording controls with a live digital stopwatch and sample counter.
* **One-Click CSV Dataset Export**:
  * Standardized tabular export formatted for research analysis in Excel, Python (`pandas`), R, or MATLAB.
* **Participant Profile Interface**:
  * Create and tag recordings with participant IDs (e.g. `PART-001`, `PART-002`) to maintain clean data separation across experimental trials.
* **Autonomic Reactivity Trend Visualization**:
  * An exploratory research indicator combining EDA and vagal modulation. Accompanied by prominent academic non-diagnostic disclaimers.
* **Zero Dependency Local Server**:
  * Runs instantly with Python 3 (already installed on Windows) using `python serve.py` or double-clicking `run.bat`.

---

## 🎨 Design & UI Architecture

EmotiGuard features a premium health-tech aesthetic:
* **Color Palette**: Dark Navy foundation (`#070D1B`, `#091024`, `#0D172C`) with Cyber Cyan (`#06B6D4`), Vivid Violet (`#8B5CF6`), Electric Blue (`#3B82F6`), and Rose (`#F43F5E`) telemetry highlights.
* **Glassmorphism**: Translucent panels with backdrop blur and responsive hover elevations.
* **Responsive Layout**: Adapts smoothly to mobile phones (touch hamburger drawer), tablets, and high-resolution desktop screens.
* **State Management**: Distinct, non-confusing views for **Disconnected**, **Demo Mode**, **Scanning**, and **Active BLE Telemetry**.

---

## 🚀 Quick Start & Local Launch

### Method 1: Windows One-Click (Recommended)
1. Double-click the file **`run.bat`** in the project folder.
2. The server will start and automatically open your default browser at:
   ```
   http://localhost:8000
   ```

### Method 2: Command Line (Windows / macOS / Linux)
Open PowerShell or your terminal in this directory and execute:
```bash
python serve.py
```
*(Or `python -m http.server 8000`)*

Then open **Google Chrome** or **Microsoft Edge** at [http://localhost:8000](http://localhost:8000).

> **Important**: The **Web Bluetooth API** requires a secure context. Operating on `http://localhost:8000` or `http://127.0.0.1:8000` satisfies browser security requirements.

---

## 📱 Mobile Device Testing

To test on an Android phone over local Wi-Fi:
1. Ensure your computer and phone are connected to the same Wi-Fi network.
2. Run `python serve.py` in your terminal; it will print your local IP (e.g. `http://192.168.1.5:8000`).
3. For Web Bluetooth on Android:
   * Open Chrome on Android.
   * Enable Bluetooth on your phone.
   * Either use Chrome DevTools port forwarding (`chrome://inspect`) to map `localhost:8000`, or test using Demo Mode directly.
4. *iOS Note*: Safari does not support the Web Bluetooth API. On iOS, use the **Bluefy – Web BLE Browser** app from the App Store, or use EmotiGuard's built-in Demo Mode.

---

## 🧩 System Architecture

```
EmotiGuard/
├── index.html                   # Core single-page application shell
├── serve.py                     # Python local server with CORS & IP helper
├── run.bat                      # Windows 1-click execution script
├── README.md                    # Project documentation & college guide
├── package.json                 # Project descriptor
├── assets/
│   ├── css/
│   │   └── style.css            # Custom glassmorphism, glowing badges, animations
│   └── images/
│       └── logo.svg             # Vector shield & biometric pulse logo
├── js/
│   ├── app.js                   # Main application coordinator & routing
│   ├── config.js                # BLE UUIDs, thresholds, constants, disclaimers
│   ├── services/
│   │   ├── bluetoothService.js  # Web Bluetooth GATT manager & parser
│   │   ├── simulatorService.js  # Synthetic bio-signal generator (Demo mode)
│   │   ├── storageService.js    # Local persistence & participant separation
│   │   ├── sessionManager.js    # Session recorder & arousal trend engine
│   │   └── firebaseAdapter.js   # Decoupled adapter ready for Firebase Auth & Firestore
│   └── ui/
│       ├── chartManager.js      # Chart.js time-series streaming engine
│       ├── dashboardView.js     # Real-time sensor cards & gauge view
│       ├── bleView.js           # BLE scanning UI & live GATT console
│       ├── participantView.js   # Participant manager & profiles
│       └── exportView.js        # Recorded sessions & CSV generator
└── firmware/
    └── EmotiGuard_ESP32.ino     # Complete Arduino ESP32 BLE firmware
```

---

## 🔬 Sensor Specifications & Physiological Metrics

| Metric | Measurement | Unit | Typical Range | Physiological Meaning |
| :--- | :--- | :---: | :---: | :--- |
| **Heart Rate** | Pulse frequency | **BPM** | 60 – 100 | Rate of cardiac ventricular contractions. |
| **HRV (RMSSD)** | R-R successive diff | **ms** | 25 – 75 | Parasympathetic (vagal) cardiac autonomic control. |
| **Blood Oxygen (SpO₂)** | PPG light absorption | **%** | 95 – 100 | Peripheral capillary hemoglobin oxygen saturation. |
| **Skin Conductance** | Electrodermal activity | **µS** | 1.5 – 15.0 | Sympathetic sweat gland secretion (EDA / GSR). |

---

## 📡 Web Bluetooth API & GATT Specifications

EmotiGuard supports both standard Bluetooth SIG services and the custom EmotiGuard multi-sensor profile:

* **Primary Service UUID**: `0000ffe0-0000-1000-8000-00805f9b34fb`
* **Telemetry Characteristic UUID**: `0000ffe1-0000-1000-8000-00805f9b34fb` (Properties: `READ`, `NOTIFY`)
* **Standard Heart Rate Service UUID**: `0x180D` (Characteristic `0x2A37`)

### Telemetry Packet Payload (JSON or CSV)
The ESP32 broadcasts a 1 Hz notification formatted as:
```json
{"hr": 74, "hrv": 48, "spo2": 98.4, "gsr": 4.25}
```
*Alternatively, comma-separated values (`"74,48,98.4,4.25"`) or packed 6-byte binary structures are supported.*

---

## ⚡ ESP32 Hardware Wiring & Firmware

The complete, compile-ready Arduino sketch is located in [firmware/EmotiGuard_ESP32.ino](file:///c:/Users/palj2/OneDrive/Desktop/New%20folder%20%282%29/firmware/EmotiGuard_ESP32.ino).

### Pin Connections

#### 1. Pulse / PPG Sensor (MAX30102)
* **VIN** $\rightarrow$ ESP32 **3.3V**
* **GND** $\rightarrow$ ESP32 **GND**
* **SDA** $\rightarrow$ ESP32 **GPIO 21**
* **SCL** $\rightarrow$ ESP32 **GPIO 22**

#### 2. Galvanic Skin Response (GSR / EDA)
* **VCC** $\rightarrow$ ESP32 **3.3V**
* **GND** $\rightarrow$ ESP32 **GND**
* **SIG** $\rightarrow$ ESP32 **GPIO 34** (ADC1 Channel 6)

### How to Flash:
1. Open the Arduino IDE.
2. Install the **ESP32 by Espressif Systems** board package (`Tools -> Board -> Boards Manager`).
3. Open `firmware/EmotiGuard_ESP32.ino`.
4. Select board **ESP32 Dev Module** and the appropriate COM port.
5. Click **Upload**. Open Serial Monitor at **115200 baud** to verify that advertising starts.

---

## 📊 Session Recording & CSV Export

1. Select your target **Participant ID** in the top navigation or sidebar.
2. Click **Start Session**. The live stopwatch and sample count will begin incrementing.
3. Once completed, click **Stop & Save**.
4. Navigate to the **Export CSV & History** tab.
5. Click **CSV** to download the session. The generated CSV contains:
   ```csv
   Timestamp_ISO,Timestamp_Local,Participant_ID,Session_ID,Heart_Rate_BPM,HRV_RMSSD_ms,SpO2_Percent,Skin_Conductance_uS,Telemetry_Source
   "2026-10-15T15:20:00.000Z","8:50:00 PM","PART-001","SESS-MF2021",72,48,98.2,4.25,"BLE"
   ```

---

## 👤 Participant Profiles & Data Separation

* EmotiGuard provides an interface to organize recordings by participant profiles (`PART-001`, `PART-002`, etc.) with age, alias, and baseline notes.
* **Security Notice**: In accordance with the technical specifications, Participant IDs in Version 1 are used strictly for **local experimental data separation**. They are not treated as secure user authentication tokens.

---

## ☁️ Phase 2 Roadmap: Firebase Auth & Firestore

A clean adapter pattern has been prepared in `js/services/firebaseAdapter.js`. To connect Cloud Firebase in Phase 2:
1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Firebase Authentication** (Google / Email sign-in).
3. Create a **Cloud Firestore** database.
4. Pass your project configuration into `firebaseAdapter.init(firebaseConfig)`.
5. Call `firebaseAdapter.syncSession(session)` when a session stops to automatically sync recordings to cloud collections `/participants/{id}/sessions/{sessionId}`.

---

## ⚖️ Academic & Research Disclaimers

> **EMOTIGUARD RESEARCH NOTICE**  
> This application and hardware design are educational prototypes developed for IoT and bio-signal telemetry demonstration.  
> 
> Physiological trend visualizations (such as the Autonomic Reactivity Index) reflect exploratory autonomous nervous system metrics (EDA and HRV RMSSD) and **MUST NOT** be interpreted as clinical diagnoses of emotional states, psychiatric conditions, or medical disorders.  
> 
> Demo mode synthetic values are explicitly tagged `DEMO` and must never be conflated with real physical sensor readings.

---

*EmotiGuard — College IoT Capstone Project.*
