/**
 * smart_home_common.h
 * 智能家居 ESP32 公共库
 * 包含：WiFi 连接、MQTT 通信、UDP 设备发现
 * 
 * 所有设备固件都引用此库
 */

#ifndef SMART_HOME_COMMON_H
#define SMART_HOME_COMMON_H

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <WiFiUdp.h>

// ══════════════════════════════════════════
// 配置参数（修改这里适配你的环境）
// ══════════════════════════════════════════

// WiFi 配置
const char* WIFI_SSID = "你的WiFi名称";        // 改成你家的 WiFi
const char* WIFI_PASSWORD = "你的WiFi密码";     // 改成你家的 WiFi 密码

// MQTT Broker 配置
const char* MQTT_BROKER = "192.168.1.100";      // 改成你的 MQTT Broker IP
const int MQTT_PORT = 1883;
const char* MQTT_USER = "";                      // 留空表示无认证
const char* MQTT_PASS = "";

// 设备配置（每个设备固件单独设置）
// const char* DEVICE_NAME = "客厅灯";
// const char* DEVICE_TYPE = "light";
// const char* TOPIC_PREFIX = "home/livingroom/light";

// UDP 发现端口（与 App 一致）
const int UDP_DISCOVERY_PORT = 4210;

// 心跳间隔（毫秒）
const unsigned long HEARTBEAT_INTERVAL = 30000;  // 30秒

// ══════════════════════════════════════════
// 全局对象
// ══════════════════════════════════════════

WiFiClient espClient;
PubSubClient mqttClient(espClient);
WiFiUDP udp;

unsigned long lastHeartbeat = 0;
unsigned long lastReconnectAttempt = 0;

// 回调函数类型定义
typedef void (*MessageCallback)(char* topic, byte* payload, unsigned int length);
MessageCallback userCallback = nullptr;

// ══════════════════════════════════════════
// WiFi 连接
// ══════════════════════════════════════════

void setupWifi() {
  delay(10);
  Serial.println();
  Serial.print("[WiFi] 连接: ");
  Serial.println(WIFI_SSID);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("[WiFi] 已连接! IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println();
    Serial.println("[WiFi] 连接失败! 将继续重试...");
  }
}

void checkWifi() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[WiFi] 断开，重新连接...");
    WiFi.reconnect();
    delay(3000);
  }
}

// ══════════════════════════════════════════
// MQTT 通信
// ══════════════════════════════════════════

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // 打印收到的消息
  Serial.print("[MQTT] 收到: ");
  Serial.print(topic);
  Serial.print(" → ");
  
  char message[256];
  for (unsigned int i = 0; i < length && i < 255; i++) {
    message[i] = (char)payload[i];
  }
  message[length] = '\0';
  Serial.println(message);

  // 调用用户回调
  if (userCallback) {
    userCallback(topic, payload, length);
  }
}

void setupMqtt(const char* clientId) {
  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(512);
  
  Serial.print("[MQTT] 连接: ");
  Serial.print(MQTT_BROKER);
  Serial.print(":");
  Serial.println(MQTT_PORT);
}

bool reconnectMqtt(const char* clientId, const char* subscribeTopic) {
  if (mqttClient.connected()) return true;

  unsigned long now = millis();
  if (now - lastReconnectAttempt < 5000) return false;
  lastReconnectAttempt = now;

  Serial.print("[MQTT] 尝试连接...");

  bool connected;
  if (strlen(MQTT_USER) > 0) {
    connected = mqttClient.connect(clientId, MQTT_USER, MQTT_PASS);
  } else {
    connected = mqttClient.connect(clientId);
  }

  if (connected) {
    Serial.println(" 成功!");
    // 订阅控制主题
    if (subscribeTopic) {
      mqttClient.subscribe(subscribeTopic);
      Serial.print("[MQTT] 已订阅: ");
      Serial.println(subscribeTopic);
    }
    return true;
  } else {
    Serial.print(" 失败, rc=");
    Serial.println(mqttClient.state());
    return false;
  }
}

void publishStatus(const char* topic, const char* payload) {
  if (mqttClient.connected()) {
    mqttClient.publish(topic, payload);
    Serial.print("[MQTT] 发布: ");
    Serial.print(topic);
    Serial.print(" → ");
    Serial.println(payload);
  }
}

void sendHeartbeat(const char* topic) {
  unsigned long now = millis();
  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    lastHeartbeat = now;
    char payload[64];
    snprintf(payload, sizeof(payload), "{\"ts\":%lu}", now / 1000);
    publishStatus(topic, payload);
  }
}

// ══════════════════════════════════════════
// UDP 设备发现
// ══════════════════════════════════════════

void setupUdp() {
  udp.begin(UDP_DISCOVERY_PORT);
  Serial.print("[UDP] 监听端口: ");
  Serial.println(UDP_DISCOVERY_PORT);
}

/**
 * 处理 UDP 发现请求
 * App 发送 "smart_home_discover" 广播
 * ESP32 回复设备信息 JSON
 */
void handleUdpDiscovery(const char* deviceName, const char* deviceType, const char* topicPrefix) {
  int packetSize = udp.parsePacket();
  if (packetSize) {
    char buffer[64];
    int len = udp.read(buffer, sizeof(buffer) - 1);
    buffer[len] = '\0';

    // 检查是否是发现命令
    if (strcmp(buffer, "smart_home_discover") == 0) {
      // 构造回复 JSON
      StaticJsonDocument<256> doc;
      doc["name"] = deviceName;
      doc["type"] = deviceType;
      doc["topic"] = topicPrefix;
      doc["ip"] = WiFi.localIP().toString();
      doc["mac"] = WiFi.macAddress();
      doc["firmware"] = "1.0.0";

      char response[256];
      serializeJson(doc, response);

      // 回复发送方
      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.write((uint8_t*)response, strlen(response));
      udp.endPacket();

      Serial.print("[UDP] 回复发现请求: ");
      Serial.println(response);
    }
  }
}

// ══════════════════════════════════════════
// 主循环框架
// ══════════════════════════════════════════

/**
 * 初始化智能家居框架
 * 在 setup() 中调用
 */
void smartHomeInit(const char* deviceName, const char* deviceType, 
                   const char* topicPrefix, MessageCallback callback) {
  Serial.begin(115200);
  Serial.println("==========================");
  Serial.print("智能家居设备: ");
  Serial.println(deviceName);
  Serial.print("类型: ");
  Serial.println(deviceType);
  Serial.println("==========================");

  userCallback = callback;

  // 1. 连接 WiFi
  setupWifi();

  // 2. 设置 MQTT
  char clientId[64];
  snprintf(clientId, sizeof(clientId), "esp32_%s", WiFi.macAddress().c_str());
  setupMqtt(clientId);

  // 3. 订阅控制主题
  char setTopic[128];
  snprintf(setTopic, sizeof(setTopic), "%s/set", topicPrefix);
  reconnectMqtt(clientId, setTopic);

  // 4. 启动 UDP 发现
  setupUdp();
}

/**
 * 主循环处理
 * 在 loop() 中调用
 */
void smartHomeLoop(const char* deviceName, const char* deviceType, 
                   const char* topicPrefix) {
  // 检查 WiFi
  checkWifi();

  // 保持 MQTT 连接
  char clientId[64];
  snprintf(clientId, sizeof(clientId), "esp32_%s", WiFi.macAddress().c_str());
  char setTopic[128];
  snprintf(setTopic, sizeof(setTopic), "%s/set", topicPrefix);
  reconnectMqtt(clientId, setTopic);

  // MQTT 消息循环
  mqttClient.loop();

  // 处理 UDP 发现
  handleUdpDiscovery(deviceName, deviceType, topicPrefix);

  // 发送心跳
  char heartbeatTopic[128];
  snprintf(heartbeatTopic, sizeof(heartbeatTopic), "%s/heartbeat", topicPrefix);
  sendHeartbeat(heartbeatTopic);
}

#endif // SMART_HOME_COMMON_H
