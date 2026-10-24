#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// EmotiGuard ESP32 Wearable Configuration
// ============================================================================

// BLE GATT Service & Characteristic UUIDs (Must match Flutter BleConstants)
#define BLE_SERVICE_UUID           "19B10000-E8F2-537E-4F6C-D104768A1214"
#define BLE_SENSOR_CHAR_UUID       "19B10001-E8F2-537E-4F6C-D104768A1214"
#define BLE_COMMAND_CHAR_UUID      "19B10002-E8F2-537E-4F6C-D104768A1214"
#define BLE_DEVICE_NAME            "EmotiGuard Wearable"

// Hardware Pinout Definitions
// I2C Pins (MAX30102 Heart Rate + MPU6050 Accelerometer)
#define PIN_I2C_SDA                21
#define PIN_I2C_SCL                22

// Grove GSR Sensor Analog Input (ADC1 pin required when BLE is active)
#define PIN_GSR_ANALOG             34

// Streaming & Timing Configuration
#define SENSOR_STREAM_INTERVAL_MS  5000  // Stream every 5 seconds
#define SENSOR_SAMPLE_INTERVAL_MS  50    // High-speed internal acquisition loop

// Optional Wi-Fi / MQTT Backend Uplink (Can be enabled if direct Wi-Fi sync is desired)
#define ENABLE_WIFI_MQTT           false
#define WIFI_SSID                  "YOUR_WIFI_SSID"
#define WIFI_PASSWORD              "YOUR_WIFI_PASSWORD"
#define MQTT_BROKER_HOST           "192.168.1.100"
#define MQTT_BROKER_PORT           1883
#define MQTT_TOPIC_SENSOR          "emotiguard/device_01/sensor"

#endif // CONFIG_H
