#ifndef BLE_SERVICE_H
#define BLE_SERVICE_H

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "config.h"
#include "sensor_manager.h"

class BleServiceManager : public BLEServerCallbacks {
private:
  BLEServer* pServer = nullptr;
  BLECharacteristic* pSensorChar = nullptr;
  BLECharacteristic* pCommandChar = nullptr;
  bool deviceConnected = false;
  bool oldDeviceConnected = false;

public:
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("[BLE] Client phone connected to EmotiGuard Wearable!");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("[BLE] Client disconnected. Restarting advertising...");
  }

  void begin() {
    BLEDevice::init(BLE_DEVICE_NAME);

    // Create BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(this);

    // Create Primary GATT Service
    BLEService* pService = pServer->createService(BLE_SERVICE_UUID);

    // Sensor Stream Characteristic (Notify + Read)
    pSensorChar = pService->createCharacteristic(
      BLE_SENSOR_CHAR_UUID,
      BLECharacteristic::PROPERTY_READ |
      BLECharacteristic::PROPERTY_NOTIFY
    );
    pSensorChar->addDescriptor(new BLE2902());

    // Command Characteristic (Write for configuration / threshold adjustments)
    pCommandChar = pService->createCharacteristic(
      BLE_COMMAND_CHAR_UUID,
      BLECharacteristic::PROPERTY_WRITE
    );

    pService->start();

    // Start Advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(BLE_SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06); // Functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("[BLE] EmotiGuard BLE Service started and advertising.");
  }

  bool isConnected() const {
    return deviceConnected;
  }

  // Formats JSON payload and notifies connected Flutter client
  void notifyReading(const SensorReading& r) {
    char jsonBuffer[256];
    snprintf(
      jsonBuffer,
      sizeof(jsonBuffer),
      "{\"ts\":%u,\"hr\":%.1f,\"hrv\":%.1f,\"eda\":%.2f,\"accel\":{\"x\":%.3f,\"y\":%.3f,\"z\":%.3f},\"cs\":%u}\n",
      r.timestamp,
      r.heartRate,
      r.hrvRmssd,
      r.edaMicroSiemens,
      r.accelX,
      r.accelY,
      r.accelZ,
      r.checksum
    );

    // Print to Serial for debugging & terminal inspection
    Serial.print("[STREAM 5s] ");
    Serial.print(jsonBuffer);

    // If BLE client is connected, dispatch GATT Notification
    if (deviceConnected && pSensorChar != nullptr) {
      pSensorChar->setValue((uint8_t*)jsonBuffer, strlen(jsonBuffer));
      pSensorChar->notify();
    }

    // Handle advertising restart on disconnect
    if (!deviceConnected && oldDeviceConnected) {
      delay(500);
      pServer->startAdvertising();
      oldDeviceConnected = deviceConnected;
    }
    if (deviceConnected && !oldDeviceConnected) {
      oldDeviceConnected = deviceConnected;
    }
  }
};

#endif // BLE_SERVICE_H
