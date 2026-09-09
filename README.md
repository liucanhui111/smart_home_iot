# 🏠 智能家居 IoT App

本地自建智能家居控制应用，完全基于 MQTT 本地通信，无云服务依赖。

## 功能

- **设备管理**：手动添加设备，支持灯/开关/传感器/风扇/温控器等类型
- **动态控制**：根据设备类型自动生成控件（开关、滑块、数值显示）
- **联动规则**：配置「当 A 满足条件时，执行 B 动作」的自动化规则
- **MQTT 通信**：连接本地 Broker，实时收发设备状态
- **主题切换**：支持深色/浅色主题

## 快速开始

### 1. 环境准备

确保已安装 Flutter SDK（3.x+）：

```bash
flutter doctor
```

### 2. 配置 MQTT Broker

编辑 `lib/constants.dart`，修改你的 Broker 地址：

```dart
static const String mqttBrokerIp = '192.168.1.100';  // 改为你的 IP
static const int mqttBrokerPort = 1883;
```

### 3. 安装依赖

```bash
cd smart_home_iot
flutter pub get
```

### 4. 运行调试

```bash
flutter run
```

### 5. 打包 APK

```bash
flutter build apk --release
# 产物路径: build/app/outputs/flutter-apk/app-release.apk
```

## MQTT 协议约定

设备需遵循以下主题格式：

| 主题 | 方向 | 用途 | Payload 示例 |
|------|------|------|-------------|
| `{prefix}/status` | 设备→App | 属性上报 | `{"power":true,"brightness":80}` |
| `{prefix}/set` | App→设备 | 控制下发 | `{"power":false}` |
| `{prefix}/heartbeat` | 设备→App | 心跳保活 | `{"ts":1694236800}` |

## 项目结构

```
lib/
├── main.dart                    # 入口
├── app.dart                     # MaterialApp + 主题
├── constants.dart               # 配置常量
├── models/                      # 数据模型
│   ├── device.dart
│   ├── device_property.dart
│   └── automation_rule.dart
├── services/                    # 核心服务
│   ├── mqtt_service.dart        # MQTT 通信
│   ├── database_service.dart    # SQLite 存储
│   └── rule_engine.dart         # 联动规则引擎
├── providers/                   # 状态管理
│   ├── device_provider.dart
│   ├── theme_provider.dart
│   └── rule_provider.dart
├── screens/                     # 页面
│   ├── home_screen.dart
│   ├── device_add_screen.dart
│   ├── device_control_screen.dart
│   ├── automation_list_screen.dart
│   └── automation_edit_screen.dart
└── widgets/                     # 通用组件
    ├── device_card.dart
    ├── property_widget.dart
    └── rule_condition_tile.dart
```

## 扩展方向

- [ ] 设备自动发现（mDNS / UDP 广播）
- [ ] 场景模式（一键执行多设备联动）
- [ ] 传感器历史数据图表（fl_chart）
- [ ] 本地通知推送
- [ ] 设备分组/房间管理
- [ ] 多 Broker 支持
