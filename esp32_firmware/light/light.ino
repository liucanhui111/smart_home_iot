/**
 * ESP32 灯设备固件
 * 功能：开关控制 + 亮度调节
 * 
 * 接线：
 *   LED/继电器 → GPIO 2
 *   PWM 调光   → GPIO 4 (可选)
 * 
 * MQTT 主题：
 *   上报状态: {topicPrefix}/status
 *   接收控制: {topicPrefix}/set
 *   心跳:     {topicPrefix}/heartbeat
 */

#include "smart_home_common.h"

// ══════════════════════════════════════════
// 设备配置（根据实际修改）
// ══════════════════════════════════════════

const char* DEVICE_NAME = "客厅灯";
const char* DEVICE_TYPE = "light";
const char* TOPIC_PREFIX = "home/livingroom/light";

// GPIO 引脚
const int LED_PIN = 2;           // 开关控制引脚
const int PWM_PIN = 4;           // PWM 调光引脚（可选）
const int PWM_CHANNEL = 0;       // PWM 通道
const int PWM_FREQ = 5000;       // PWM 频率
const int PWM_RESOLUTION = 8;    // PWM 分辨率 (0-255)

// ══════════════════════════════════════════
// 设备状态
// ══════════════════════════════════════════

bool powerState = false;
int brightness = 100;  // 0-100

// ══════════════════════════════════════════
// 状态上报
// ══════════════════════════════════════════

void reportStatus() {
  char statusTopic[128];
  snprintf(statusTopic, sizeof(statusTopic), "%s/status", TOPIC_PREFIX);

  StaticJsonDocument<128> doc;
  doc["power"] = powerState;
  doc["brightness"] = brightness;

  char payload[128];
  serializeJson(doc, payload);
  publishStatus(statusTopic, payload);
}

// ══════════════════════════════════════════
// 设备控制
// ══════════════════════════════════════════

void applyState() {
  // 开关控制
  digitalWrite(LED_PIN, powerState ? HIGH : LOW);

  // 亮度控制（PWM）
  if (powerState) {
    int pwmValue = map(brightness, 0, 100, 0, 255);
    ledcWrite(PWM_PIN, pwmValue);
  } else {
    ledcWrite(PWM_PIN, 0);
  }

  Serial.printf("[灯] 电源: %s, 亮度: %d%%\n", 
                powerState ? "开" : "关", brightness);
}

// ══════════════════════════════════════════
// MQTT 消息处理
// ══════════════════════════════════════════

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  // 解析 JSON
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  
  if (error) {
    Serial.print("[灯] JSON 解析失败: ");
    Serial.println(error.c_str());
    return;
  }

  // 处理电源控制
  if (doc.containsKey("power")) {
    powerState = doc["power"].as<bool>();
  }

  // 处理亮度控制
  if (doc.containsKey("brightness")) {
    brightness = doc["brightness"].as<int>();
    brightness = constrain(brightness, 0, 100);
  }

  // 应用状态
  applyState();
  
  // 上报新状态
  reportStatus();
}

// ══════════════════════════════════════════
// Arduino 主程序
// ══════════════════════════════════════════

void setup() {
  // 初始化 GPIO
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // 设置 PWM
  ledcAttach(PWM_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcWrite(PWM_PIN, 0);

  // 初始化智能家居框架
  smartHomeInit(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX, onMqttMessage);

  // 上报初始状态
  reportStatus();
}

void loop() {
  // 主循环处理
  smartHomeLoop(DEVICE_NAME, DEVICE_TYPE, TOPIC_PREFIX);
}
