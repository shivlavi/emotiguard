/**
 * EmotiGuard Web Bluetooth API Service
 * Handles device discovery, GATT connection lifecycle, notification streams,
 * and robust error recovery for the ESP32 wearable unit.
 */

import { APP_CONFIG } from '../config.js';

export const BLE_STATES = {
  DISCONNECTED: 'DISCONNECTED',
  SCANNING: 'SCANNING',
  CONNECTING: 'CONNECTING',
  CONNECTED: 'CONNECTED',
  ERROR: 'ERROR'
};

export class BluetoothService {
  constructor(callbacks = {}) {
    this.onData = callbacks.onData || (() => {});
    this.onStateChange = callbacks.onStateChange || (() => {});
    this.onLog = callbacks.onLog || (() => {});

    this.device = null;
    this.server = null;
    this.customService = null;
    this.customChar = null;
    this.hrChar = null;
    this.state = BLE_STATES.DISCONNECTED;
    
    // Rolling R-R buffer to compute RMSSD if raw RR intervals are received from standard HR strap
    this.rrIntervals = [];
  }

  isSupported() {
    return typeof navigator !== 'undefined' && 'bluetooth' in navigator;
  }

  getSupportDetails() {
    if (this.isSupported()) {
      return { supported: true, message: 'Web Bluetooth API is available.' };
    }

    const ua = navigator.userAgent;
    let hint = 'Please use Google Chrome, Microsoft Edge, Opera, or Chrome for Android.';
    if (/iPhone|iPad|iPod/.test(ua)) {
      hint = 'iOS Safari does not support Web Bluetooth natively. Please use the "Bluefy" or "WebBLE" browser from the App Store, or run in Demo Mode.';
    } else if (/Firefox/.test(ua)) {
      hint = 'Mozilla Firefox does not implement Web Bluetooth due to internal privacy policies. Please switch to Google Chrome or Microsoft Edge.';
    }

    return {
      supported: false,
      message: `Web Bluetooth is not supported in this browser. ${hint}`
    };
  }

  setState(newState, details = null) {
    this.state = newState;
    this.onStateChange(newState, details);
  }

  log(msg, level = 'info') {
    const time = new Date().toLocaleTimeString();
    this.onLog(`[${time}] ${msg}`, level);
  }

  async connect() {
    if (!this.isSupported()) {
      const err = this.getSupportDetails().message;
      this.setState(BLE_STATES.ERROR, err);
      this.log(err, 'error');
      throw new Error(err);
    }

    try {
      this.setState(BLE_STATES.SCANNING);
      this.log('Opening Web Bluetooth device picker...');

      // Request device with optional services configured
      const device = await navigator.bluetooth.requestDevice({
        filters: [
          { namePrefix: 'EmotiGuard' },
          { services: [APP_CONFIG.BLE.CUSTOM_SERVICE_UUID] },
          { services: [APP_CONFIG.BLE.STANDARD_HR_SERVICE_UUID] }
        ],
        optionalServices: [
          APP_CONFIG.BLE.CUSTOM_SERVICE_UUID,
          APP_CONFIG.BLE.STANDARD_HR_SERVICE_UUID,
          APP_CONFIG.BLE.BATTERY_SERVICE_UUID
        ]
      }).catch(err => {
        // Fallback filter to allow user to connect any Bluetooth device advertising standard or custom
        this.log('Retrying with broad device discovery filter...', 'warn');
        return navigator.bluetooth.requestDevice({
          acceptAllDevices: true,
          optionalServices: [
            APP_CONFIG.BLE.CUSTOM_SERVICE_UUID,
            APP_CONFIG.BLE.STANDARD_HR_SERVICE_UUID,
            APP_CONFIG.BLE.BATTERY_SERVICE_UUID
          ]
        });
      });

      this.device = device;
      this.log(`Selected device: "${device.name || 'Unnamed Device'}" (ID: ${device.id})`);

      // Set up disconnect listener
      this.device.addEventListener('gattserverdisconnected', (event) => {
        this.handleDisconnect(event);
      });

      this.setState(BLE_STATES.CONNECTING, `Connecting to ${device.name || 'ESP32'}...`);
      this.log('Initiating GATT Server connection...');

      const server = await this.device.gatt.connect();
      this.server = server;
      this.log('GATT Server connected successfully. Discovering primary services...');

      let servicesFound = 0;

      // 1. Try connecting to custom EmotiGuard service
      try {
        const customService = await server.getPrimaryService(APP_CONFIG.BLE.CUSTOM_SERVICE_UUID);
        this.customService = customService;
        this.log(`Found EmotiGuard Custom Service (${APP_CONFIG.BLE.CUSTOM_SERVICE_UUID})`);

        const customChar = await customService.getCharacteristic(APP_CONFIG.BLE.CUSTOM_DATA_CHAR_UUID);
        this.customChar = customChar;
        await customChar.startNotifications();
        customChar.addEventListener('characteristicvaluechanged', (e) => this.handleCustomData(e));
        this.log('Subscribed to EmotiGuard multi-sensor telemetry stream.');
        servicesFound++;
      } catch (e) {
        this.log(`Custom EmotiGuard service not active: ${e.message}`, 'warn');
      }

      // 2. Try connecting to standard Heart Rate service
      try {
        const hrService = await server.getPrimaryService(APP_CONFIG.BLE.STANDARD_HR_SERVICE_UUID);
        this.log('Found standard Bluetooth SIG Heart Rate Service.');
        const hrChar = await hrService.getCharacteristic(APP_CONFIG.BLE.STANDARD_HR_CHAR_UUID);
        this.hrChar = hrChar;
        await hrChar.startNotifications();
        hrChar.addEventListener('characteristicvaluechanged', (e) => this.handleStandardHeartRate(e));
        this.log('Subscribed to standard Heart Rate notifications.');
        servicesFound++;
      } catch (e) {
        this.log(`Standard Heart Rate service not present: ${e.message}`, 'warn');
      }

      if (servicesFound === 0) {
        throw new Error('Connected to device, but neither EmotiGuard service nor Standard Heart Rate service was discovered.');
      }

      this.setState(BLE_STATES.CONNECTED, {
        deviceName: device.name || 'EmotiGuard ESP32',
        deviceId: device.id
      });
      this.log('Telemetry pipeline active and streaming.');

      return true;
    } catch (error) {
      this.log(`Connection failed: ${error.message}`, 'error');
      this.setState(BLE_STATES.ERROR, error.message);
      return false;
    }
  }

  async disconnect() {
    if (this.device && this.device.gatt.connected) {
      this.log('Disconnecting from BLE device...');
      this.device.gatt.disconnect();
    }
    this.handleDisconnect();
  }

  handleDisconnect(event) {
    this.log('ESP32 device disconnected.', 'warn');
    this.server = null;
    this.customService = null;
    this.customChar = null;
    this.hrChar = null;
    this.setState(BLE_STATES.DISCONNECTED);
  }

  /**
   * Parses incoming packets from EmotiGuard custom BLE characteristic.
   * Supports:
   * 1. JSON string: {"hr":75,"hrv":45,"spo2":98,"gsr":4.5}
   * 2. Comma-separated text: "75,45,98,4.5"
   * 3. Packed binary (8 bytes): [uint8 hr, uint8 spo2, uint16 hrv, uint16 gsr*100, uint16 reserved]
   */
  handleCustomData(event) {
    const value = event.target.value;
    try {
      // First try decoding as UTF-8 string (JSON or CSV)
      const decoder = new TextDecoder('utf-8');
      const text = decoder.decode(value).trim();

      let sample = null;

      if (text.startsWith('{') && text.endsWith('}')) {
        const parsed = JSON.parse(text);
        sample = {
          hr: Math.round(Number(parsed.hr || parsed.heartRate || 0)),
          hrv: Math.round(Number(parsed.hrv || parsed.rmssd || 0)),
          spo2: parseFloat(Number(parsed.spo2 || 0).toFixed(1)),
          gsr: parseFloat(Number(parsed.gsr || parsed.eda || 0).toFixed(2))
        };
      } else if (text.includes(',')) {
        const parts = text.split(',');
        sample = {
          hr: Math.round(Number(parts[0])),
          hrv: Math.round(Number(parts[1] || 0)),
          spo2: parseFloat(Number(parts[2] || 0).toFixed(1)),
          gsr: parseFloat(Number(parts[3] || 0).toFixed(2))
        };
      } else if (value.byteLength >= 6) {
        // Packed binary format
        // byte 0: HR (uint8)
        // byte 1: SpO2 (uint8)
        // byte 2-3: HRV RMSSD (uint16 little endian)
        // byte 4-5: GSR * 100 (uint16 little endian)
        const hr = value.getUint8(0);
        const spo2 = value.getUint8(1);
        const hrv = value.getUint16(2, true);
        const gsrRaw = value.getUint16(4, true);
        sample = {
          hr,
          spo2,
          hrv,
          gsr: parseFloat((gsrRaw / 100).toFixed(2))
        };
      }

      if (sample && sample.hr > 0) {
        const telemetryPoint = {
          timestamp: new Date().toISOString(),
          timestampLocal: new Date().toLocaleTimeString(),
          hr: sample.hr,
          hrv: sample.hrv || 45,
          spo2: sample.spo2 || 98.0,
          gsr: sample.gsr || 3.5,
          source: 'BLE'
        };

        this.onData(telemetryPoint);
      }
    } catch (err) {
      this.log(`Error parsing BLE sensor packet: ${err.message}`, 'error');
    }
  }

  /**
   * Standard Bluetooth SIG Heart Rate Measurement Characteristic Parser (0x2A37)
   */
  handleStandardHeartRate(event) {
    const value = event.target.value;
    const flags = value.getUint8(0);
    const rate16Bits = flags & 0x01;
    let index = 1;

    let heartRate = 0;
    if (rate16Bits) {
      heartRate = value.getUint16(index, true);
      index += 2;
    } else {
      heartRate = value.getUint8(index);
      index += 1;
    }

    // Check if RR-Intervals are present (Bit 4 of flags is 1)
    let calculatedRMSSD = 45; // Default fallback
    const rrPresent = (flags & 0x10) !== 0;
    if (rrPresent && (value.byteLength >= index + 2)) {
      while (index + 2 <= value.byteLength) {
        // RR-Interval value in 1/1024 seconds, convert to ms
        const rrRaw = value.getUint16(index, true);
        const rrMs = Math.round((rrRaw / 1024) * 1000);
        this.rrIntervals.push(rrMs);
        if (this.rrIntervals.length > 30) this.rrIntervals.shift();
        index += 2;
      }
      calculatedRMSSD = this.calculateRMSSD(this.rrIntervals);
    }

    const telemetryPoint = {
      timestamp: new Date().toISOString(),
      timestampLocal: new Date().toLocaleTimeString(),
      hr: heartRate,
      hrv: calculatedRMSSD,
      spo2: 98.0, // standard HR strap doesn't provide SpO2
      gsr: 3.2,   // standard HR strap doesn't provide GSR
      source: 'BLE'
    };

    this.onData(telemetryPoint);
  }

  calculateRMSSD(intervals) {
    if (intervals.length < 3) return 45;
    let sumSquaredDiffs = 0;
    let count = 0;
    for (let i = 1; i < intervals.length; i++) {
      const diff = intervals[i] - intervals[i - 1];
      sumSquaredDiffs += diff * diff;
      count++;
    }
    return Math.round(Math.sqrt(sumSquaredDiffs / count));
  }
}
