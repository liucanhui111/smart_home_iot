/**
 * ESP32 温湿度传感器固件
 * 功能：读取 DHT11/DHT22 温湿度数据并上报
 * 
 * 接线：
 *   DHT11/22 数据引脚 → GPIO 5
 *   VCC → 3.3V
 *   GND → GND
 * 
 * MQTT 主题：
 *   上报状态: {topicPrefix}/status  {"temperature":25.5,"humidity":60.0}
 *   心跳:     {topicPrefix}/heartbeat
 *   （传感器为只读设备，不接收 set 命令）
 */

#include "smart_home_common.h"
#include <DHT.h>

// ══════════════════════════════════════════
// 设备配置
// ══════════════════════════════════════════

const char* DEVICE_NAME = "温度传感器";
const char* DEVICE_TYPE = "sensor";
const char* TOPIC_PREFIX = "home/livingroom/sensor";

// DHT 传感器配置
const int DHT_PIN = 5;
const int DHT_TYPE = DHT22;  // DHT11 或 DHT22

// 上报间隔（毫秒）
const unsigned long REPORT_INTERVAL = 10000;  // 10秒

// ══════════════════════════════════════════
// 全局对象和状态
// ══════════════════════════════════════════

DHT dht(DHT_PIN, DHT_TYPE);
unsigned long lastReport = 0;
float temperature = 0;
float humidity = 0;

// ══════════════════════════════════════════
// 状态上报
// ══════════════════════════════════════════

void reportStatus() {
  char statusTopic[128];
  snprintf(statusTopic, sizeof(statusTopic), "%s/status", TOPIC_PREFIX);

  StaticJsonDocument<128> doc;
  doc["temperature"] = round(temperature * 10) / 10.0;  // 保留1位小数
  doc["humidity"] = round(humidity * 10) / 10.0;

  char payload[128];
  serializeJson(doc, payload);
  publishStatus(statusTopic, payload);
}

// ══════════════════════════════════════════
// 传感器读取
// ══════════════════════════════════════════

void readSensor() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h)) {
    Serial.println("[传感器] 读取失败!");
    return;
  }

  temperature = t;
  humidity = h;

  Serial.printf("[传感器] 温度: %.1f°C, 湿度: %.1f%%\n", temperature, humidity);
}

// ══════════════════════════════════════════
// MQTT 消息处理（传感器一般不需要处理控制命令）
// ══════════════════════════════════════════

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  // 传感器为只读设备，收到控制命令只打印日志
  Serial.println("[传感器] 收到控制命令（只读设备，已忽略）");
}

// ══════════════════════════════════════════
// Arduino 主程序
// ══════════════════════════════════════════

void setup() {
  // 初始化 DHT 传感器
  dht.begin();

  // 初始化智能家居框架
  smartHomeInit(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX, onMqttMessage);
}

void loop() {
  // 主循环处理
  smartHomeLoop(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX);

  // 定时读取并上报传感器数据
  unsigned long now = millis();
  if (now - lastReport >= REPORT_INTERVAL) {
    lastReport = now;
    readSensor();
    reportStatus();
  }
}
