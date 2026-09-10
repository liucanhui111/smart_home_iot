/**
 * ESP32 开关设备固件
 * 功能：简单的开/关控制（继电器控制家电）
 * 
 * 接线：
 *   继电器信号引脚 → GPIO 2
 *   继电器 COM → 火线
 *   继电器 NO  → 负载（灯/风扇/其他）
 * 
 * MQTT 主题：
 *   上报状态: {topicPrefix}/status  {"power":true}
 *   接收控制: {topicPrefix}/set     {"power":false}
 */

#include "smart_home_common.h"

// ══════════════════════════════════════════
// 设备配置
// ══════════════════════════════════════════

const char* DEVICE_NAME = "卧室开关";
const char* DEVICE_TYPE = "switch";
const char* TOPIC_PREFIX = "home/bedroom/switch";

// GPIO 引脚
const int RELAY_PIN = 2;         // 继电器控制引脚
const int BUTTON_PIN = 0;        // 物理按钮引脚（可选）
const int LED_PIN = 15;          // 状态指示灯（可选）

// ══════════════════════════════════════════
// 设备状态
// ══════════════════════════════════════════

bool powerState = false;
unsigned long lastButtonPress = 0;
const unsigned long debounceDelay = 300;  // 按钮消抖时间

// ══════════════════════════════════════════
// 状态上报
// ══════════════════════════════════════════

void reportStatus() {
  char statusTopic[128];
  snprintf(statusTopic, sizeof(statusTopic), "%s/status", TOPIC_PREFIX);

  StaticJsonDocument<64> doc;
  doc["power"] = powerState;

  char payload[64];
  serializeJson(doc, payload);
  publishStatus(statusTopic, payload);
}

// ══════════════════════════════════════════
// 设备控制
// ══════════════════════════════════════════

void applyState() {
  digitalWrite(RELAY_PIN, powerState ? HIGH : LOW);
  digitalWrite(LED_PIN, powerState ? HIGH : LOW);

  Serial.printf("[开关] 电源: %s\n", powerState ? "开" : "关");
}

void toggleState() {
  powerState = !powerState;
  applyState();
  reportStatus();
}

// ══════════════════════════════════════════
// MQTT 消息处理
// ══════════════════════════════════════════

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  StaticJsonDocument<64> doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print("[开关] JSON 解析失败: ");
    Serial.println(error.c_str());
    return;
  }

  if (doc.containsKey("power")) {
    powerState = doc["power"].as<bool>();
    applyState();
    reportStatus();
  }
}

// ══════════════════════════════════════════
// 物理按钮处理（可选）
// ══════════════════════════════════════════

void handleButton() {
  if (digitalRead(BUTTON_PIN) == LOW) {
    unsigned long now = millis();
    if (now - lastButtonPress > debounceDelay) {
      lastButtonPress = now;
      toggleState();
    }
  }
}

// ══════════════════════════════════════════
// Arduino 主程序
// ══════════════════════════════════════════

void setup() {
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // 内部上拉电阻

  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  smartHomeInit(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX, onMqttMessage);
  reportStatus();
}

void loop() {
  smartHomeLoop(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX);
  handleButton();  // 检测物理按钮
}
