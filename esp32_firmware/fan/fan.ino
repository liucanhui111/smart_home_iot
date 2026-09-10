/**
 * ESP32 风扇设备固件
 * 功能：开关控制 + 风速调节（PWM 调速）
 * 
 * 接线：
 *   继电器/MOSFET → GPIO 2（开关）
 *   PWM 调速      → GPIO 4（可选）
 * 
 * MQTT 主题：
 *   上报状态: {topicPrefix}/status  {"power":true,"speed":3}
 *   接收控制: {topicPrefix}/set     {"power":false} 或 {"speed":5}
 */

#include "smart_home_common.h"

// ══════════════════════════════════════════
// 设备配置
// ══════════════════════════════════════════

const char* DEVICE_NAME = "客厅风扇";
const char* DEVICE_TYPE = "fan";
const char* TOPIC_PREFIX = "home/livingroom/fan";

// GPIO 引脚
const int RELAY_PIN = 2;         // 继电器控制（开关）
const int PWM_PIN = 4;           // PWM 调速引脚
const int PWM_CHANNEL = 0;
const int PWM_FREQ = 25000;      // 25kHz（适合大多数风扇）
const int PWM_RESOLUTION = 8;    // 0-255

// ══════════════════════════════════════════
// 设备状态
// ══════════════════════════════════════════

bool powerState = false;
int speed = 1;  // 1-5 档

// ══════════════════════════════════════════
// 状态上报
// ══════════════════════════════════════════

void reportStatus() {
  char statusTopic[128];
  snprintf(statusTopic, sizeof(statusTopic), "%s/status", TOPIC_PREFIX);

  StaticJsonDocument<96> doc;
  doc["power"] = powerState;
  doc["speed"] = speed;

  char payload[96];
  serializeJson(doc, payload);
  publishStatus(statusTopic, payload);
}

// ══════════════════════════════════════════
// 设备控制
// ══════════════════════════════════════════

void applyState() {
  // 开关控制
  digitalWrite(RELAY_PIN, powerState ? HIGH : LOW);

  // 风速控制（PWM）
  if (powerState) {
    int pwmValue = map(speed, 1, 5, 51, 255);  // 最低51(20%)，最高255(100%)
    ledcWrite(PWM_PIN, pwmValue);
  } else {
    ledcWrite(PWM_PIN, 0);
  }

  Serial.printf("[风扇] 电源: %s, 风速: %d档\n",
                powerState ? "开" : "关", speed);
}

// ══════════════════════════════════════════
// MQTT 消息处理
// ══════════════════════════════════════════

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<128> doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print("[风扇] JSON 解析失败: ");
    Serial.println(error.c_str());
    return;
  }

  if (doc.containsKey("power")) {
    powerState = doc["power"].as<bool>();
  }

  if (doc.containsKey("speed")) {
    speed = doc["speed"].as<int>();
    speed = constrain(speed, 1, 5);
  }

  applyState();
  reportStatus();
}

// ══════════════════════════════════════════
// Arduino 主程序
// ══════════════════════════════════════════

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  ledcAttach(PWM_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcWrite(PWM_PIN, 0);

  smartHomeInit(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX, onMqttMessage);
  reportStatus();
}

void loop() {
  smartHomeLoop(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX);
}
