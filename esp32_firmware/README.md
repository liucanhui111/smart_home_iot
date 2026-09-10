# ESP32 智能家居固件

配合智能家居 App 使用的 ESP32 设备固件。

## 支持的设备类型

| 设备 | 目录 | 功能 | 引脚 |
|------|------|------|------|
| 灯 | `light/` | 开关 + 亮度调节 | GPIO 2(开关), GPIO 4(PWM) |
| 传感器 | `sensor/` | 温湿度采集 | GPIO 5(DHT) |
| 风扇 | `fan/` | 开关 + 5档风速 | GPIO 2(继电器), GPIO 4(PWM) |
| 开关 | `switch_device/` | 开/关控制 + 物理按钮 | GPIO 2(继电器), GPIO 0(按钮) |

## 使用步骤

### 1. 安装 Arduino IDE

下载: https://www.arduino.cc/en/software

### 2. 配置 ESP32 开发板

1. Arduino IDE → 文件 → 首选项
2. 附加开发板管理器网址填入:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. 工具 → 开发板 → 开发板管理器 → 搜索 "esp32" → 安装

### 3. 安装依赖库

工具 → 管理库 → 搜索并安装:
- `PubSubClient` (MQTT 客户端)
- `ArduinoJson` (JSON 解析)
- `DHT sensor library` (温湿度传感器，sensor 固件需要)

### 4. 修改配置

打开对应设备的 `.ino` 文件，修改顶部配置:

```cpp
// WiFi 配置
const char* WIFI_SSID = "你的WiFi名称";
const char* WIFI_PASSWORD = "你的WiFi密码";

// MQTT Broker 配置
const char* MQTT_BROKER = "192.168.1.100";  // 你电脑的 IP
const int MQTT_PORT = 1883;

// 设备配置
const char* DEVICE_NAME = "客厅灯";         // 设备名称
const char* TOPIC_PREFIX = "home/livingroom/light";  // MQTT 主题
```

### 5. 编译上传

1. 工具 → 开发板 → ESP32 Dev Module
2. 工具 → 端口 → 选择 ESP32 的串口
3. 点击上传按钮

### 6. 测试

上传成功后:
1. 打开串口监视器 (115200 波特率)
2. 看到 WiFi 连接成功 + MQTT 连接成功
3. 打开手机 App → 添加设备 → 扫描设备
4. 应该能发现刚烧录的 ESP32

## 接线说明

### 灯 (light.ino)
```
ESP32 GPIO 2 → 继电器信号端
继电器 COM   → 火线
继电器 NO    → 灯的一端
灯的另一端   → 零线
```

### 传感器 (sensor.ino)
```
ESP32 GPIO 5 → DHT22 数据引脚
ESP32 3.3V   → DHT22 VCC
ESP32 GND    → DHT22 GND
(数据线和 VCC 之间接 10K 上拉电阻)
```

### 风扇 (fan.ino)
```
ESP32 GPIO 2 → MOSFET 信号端
MOSFET       → 串联在风扇电路中
```

### 开关 (switch_device.ino)
```
ESP32 GPIO 2  → 继电器信号端
ESP32 GPIO 0  → 物理按钮（按钮另一端接 GND）
ESP32 GPIO 15 → LED 指示灯（可选）
```

## MQTT 协议

所有设备遵循统一协议:

| 主题 | 方向 | 用途 |
|------|------|------|
| `{prefix}/status` | 设备→App | 属性上报 |
| `{prefix}/set` | App→设备 | 控制下发 |
| `{prefix}/heartbeat` | 设备→App | 心跳保活 |

### 各设备 payload 格式

**灯:**
```json
{"power": true, "brightness": 80}
```

**传感器:**
```json
{"temperature": 25.5, "humidity": 60.0}
```

**风扇:**
```json
{"power": true, "speed": 3}
```

**开关:**
```json
{"power": true}
```

## 常见问题

**Q: WiFi 连不上?**
- 检查 SSID 和密码是否正确
- 确保 WiFi 是 2.4GHz（ESP32 不支持 5GHz）

**Q: MQTT 连不上?**
- 确保 MQTT Broker 已启动
- 确保 ESP32 和 Broker 在同一局域网
- 检查 Broker IP 是否正确

**Q: App 扫描不到设备?**
- 确保 ESP32 和手机在同一 WiFi
- 确保 UDP 端口 4210 没被防火墙拦截
- 串口监视器看 ESP32 是否正常运行
