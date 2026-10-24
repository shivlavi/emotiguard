// ============================================================================
// EmotiGuard: IoT-based Emotional Distress Detection & Support System
// Firmware for ESP32 Wearable
// Sensors: MAX30102 (HR/HRV) + Grove GSR (EDA) + Accelerometer (Movement)
// ============================================================================

#include <Arduino.h>
#include "config.h"
#include "sensor_manager.h"
#include "ble_service.h"

#if ENABLE_WIFI_MQTT
#include <WiFi.h>
#include <PubSubClient.h>

WiFiClient espClient;
PubSubClient mqttClient(espClient);
#endif

SensorManager sensorMgr;
BleServiceManager bleMgr;

unsigned long lastStreamMillis = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n==============================================");
  Serial.println("  EmotiGuard ESP32 Wearable System Initializing");
  Serial.println("==============================================");

  // Initialize sensors
  sensorMgr.begin();

  // Initialize Bluetooth Low Energy GATT Server
  bleMgr.begin();

#if ENABLE_WIFI_MQTT
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  mqttClient.setServer(MQTT_BROKER_HOST, MQTT_BROKER_PORT);
#endif

  Serial.println("[System] Setup complete. Streaming sensor packets every 5 seconds.");
}

void loop() {
  unsigned long currentMillis = millis();

  // Broadcast sensor reading every SENSOR_STREAM_INTERVAL_MS (5000 ms)
  if (currentMillis - lastStreamMillis >= SENSOR_STREAM_INTERVAL_MS) {
    lastStreamMillis = currentMillis;

    // Acquire biometrics
    SensorReading reading = sensorMgr.readAllSensors();

    // Stream over BLE GATT Characteristic
    bleMgr.notifyReading(reading);

#if ENABLE_WIFI_MQTT
    if (WiFi.status() == WL_CONNECTED) {
      if (!mqttClient.connected()) {
        mqttClient.connect("EmotiGuardESP32");
      }
      char mqttPayload[256];
      snprintf(
        mqttPayload,
        sizeof(mqttPayload),
        "{\"ts\":%u,\"hr\":%.1f,\"hrv\":%.1f,\"eda\":%.2f,\"accel\":{\"x\":%.3f,\"y\":%.3f,\"z\":%.3f},\"cs\":%u}",
        reading.timestamp,
        reading.heartRate,
        reading.hrvRmssd,
        reading.edaMicroSiemens,
        reading.accelX,
        reading.accelY,
        reading.accelZ,
        reading.checksum
      );
      mqttClient.publish(MQTT_TOPIC_SENSOR, mqttPayload);
    }
#endif
  }

  // Small delay for RTOS task yielding
  delay(10);
}
