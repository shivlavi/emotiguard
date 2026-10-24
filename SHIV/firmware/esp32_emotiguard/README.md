# EmotiGuard ESP32 Wearable Firmware

Production-grade Arduino/ESP32 firmware matching the EmotiGuard BLE & Wi-Fi communication protocol.

## Hardware Connections & Pinouts

| Sensor Module | Physical Pin on ESP32 | Protocol / Type | Notes |
|---|---|---|---|
| **MAX30102** (Heart Rate & HRV) | GPIO 21 (SDA), GPIO 22 (SCL) | I2C (Address `0x57`) | VCC to 3.3V, GND to GND |
| **Grove GSR Sensor** (Electrodermal Activity) | GPIO 34 (ADC1_CH6) | Analog (12-bit ADC) | Use ADC1 channel (safe when BLE/WiFi active) |
| **MPU6050** (3-Axis Accelerometer) | GPIO 21 (SDA), GPIO 22 (SCL) | I2C (Address `0x68`) | Shared I2C bus with MAX30102 |

## Packet Format (JSON over BLE)

Every 5 seconds, the ESP32 broadcasts a JSON packet on GATT Characteristic `19B10001-E8F2-537E-4F6C-D104768A1214`:

```json
{
  "ts": 1729598400,
  "hr": 72.4,
  "hrv": 51.2,
  "eda": 2.35,
  "accel": { "x": 0.021, "y": 0.034, "z": 0.985 },
  "cs": 4120
}
```

### Checksum Verification
The checksum is calculated as:
```c
uint16_t checksum = (ts ^ (int)hr ^ (int)(eda * 100)) & 0xFFFF;
```
This is verified by the Flutter app before processing.

## Flashing Instructions
1. Open the Arduino IDE.
2. Install **ESP32 by Espressif Systems** via Boards Manager.
3. Select Board: `ESP32 Dev Module`.
4. Upload `esp32_emotiguard.ino`.
5. Open Serial Monitor at **115200 baud** to view real-time streaming output.
