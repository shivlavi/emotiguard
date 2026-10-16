/**
 * EmotiGuard Wearable BLE Firmware for ESP32
 * College IoT Physiological Telemetry Project
 * 
 * Hardware Compatibility:
 *  - ESP32 Development Board (NodeMCU-32S / ESP32-WROOM-32)
 *  - PPG Sensor (e.g. MAX30102 via I2C: SDA=GPIO21, SCL=GPIO22)
 *  - Electrodermal Activity / GSR Sensor (e.g. Grove GSR on GPIO 34 Analog In)
 * 
 * Bluetooth GATT Architecture:
 *  - Service UUID:        0000ffe0-0000-1000-8000-00805f9b34fb (EmotiGuard Multi-Sensor)
 *  - Characteristic UUID: 0000ffe1-0000-1000-8000-00805f9b34fb (Notify)
 *  - Optional SIG HR:     0x180D (Heart Rate Service)
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>

// BLE Definitions
#define DEVICE_NAME              "EmotiGuard-ESP32"
#define SERVICE_UUID             "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID_DATA "0000ffe1-0000-1000-8000-00805f9b34fb"

// Sensor Hardware Pin Mapping
#define PIN_GSR_ANALOG           34    // ESP32 ADC1_CH6 (Safe with Wi-Fi/BLE)
#define SAMPLING_INTERVAL_MS     1000  // 1 Hz Telemetry update rate

BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
unsigned long lastSampleTime = 0;

// Callback for connection lifecycle events
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("[BLE] Central client connected to EmotiGuard.");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("[BLE] Central client disconnected.");
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("==================================================");
  Serial.println("  EmotiGuard ESP32 Wearable Telemetry Node");
  Serial.println("==================================================");

  // Initialize Analog ADC for GSR
  pinMode(PIN_GSR_ANALOG, INPUT);
  analogReadResolution(12); // 12-bit ADC (0 - 4095)

  // Initialize BLE Stack
  BLEDevice::init(DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create EmotiGuard GATT Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create Multi-Sensor Notification Characteristic
  pDataCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_DATA,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // Descriptor for Client Characteristic Configuration (Required for Web Bluetooth notifications)
  pDataCharacteristic->addDescriptor(new BLE2902());

  // Start Service
  pService->start();

  // Start BLE Advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Advertising started as: " DEVICE_NAME);
  Serial.println("[BLE] Waiting for Web Bluetooth connection...");
}

/**
 * Reads GSR sensor on GPIO 34 and converts ADC raw value into micro-siemens (µS).
 */
float readSkinConductanceMicroSiemens() {
  int rawADC = analogRead(PIN_GSR_ANALOG);
  
  // Convert 12-bit ADC (0-4095 at 3.3V) to approximate resistance and conductance
  // Formula for typical Grove GSR divider (100k reference resistor)
  if (rawADC < 10) rawADC = 10;
  float voltage = (rawADC / 4095.0) * 3.3;
  float resistanceKOhms = ((3.3 - voltage) * 100.0) / voltage;
  
  // Conductance in micro-siemens (µS) = 1000 / Resistance(kOhms)
  float conductance_uS = 1000.0 / resistanceKOhms;
  if (conductance_uS < 0.5) conductance_uS = 0.5;
  if (conductance_uS > 35.0) conductance_uS = 35.0;

  return conductance_uS;
}

void loop() {
  unsigned long now = millis();

  // Transmit telemetry every 1000ms
  if (now - lastSampleTime >= SAMPLING_INTERVAL_MS) {
    lastSampleTime = now;

    // Read sensors (or generate realistic hardware test values if sensor disconnected)
    float gsr = readSkinConductanceMicroSiemens();

    // Pulse & SpO2 estimation (replace with MAX30102 read function when sensor attached)
    // Here we compute healthy resting test baseline
    int hr = 72 + random(-3, 4);
    int hrv = 48 + random(-5, 6);
    float spo2 = 98.2 + (random(-2, 3) * 0.1);

    // Build JSON packet
    char jsonBuffer[128];
    snprintf(jsonBuffer, sizeof(jsonBuffer),
      "{\"hr\":%d,\"hrv\":%d,\"spo2\":%.1f,\"gsr\":%.2f}",
      hr, hrv, spo2, gsr
    );

    // If BLE central is connected, send notification
    if (deviceConnected) {
      pDataCharacteristic->setValue((uint8_t*)jsonBuffer, strlen(jsonBuffer));
      pDataCharacteristic->notify();
      Serial.print("[BLE TX] -> ");
      Serial.println(jsonBuffer);
    } else {
      Serial.print("[STANDBY] Sensor read: ");
      Serial.println(jsonBuffer);
    }
  }

  // Handle auto-re-advertising on disconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("[BLE] Restarting advertising...");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}
