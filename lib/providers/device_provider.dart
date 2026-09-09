import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/device.dart';
import '../models/device_property.dart';
import '../services/mqtt_service.dart';
import '../services/database_service.dart';
import '../services/rule_engine.dart';

/// 设备状态管理 Provider
/// 管理设备列表、属性状态、MQTT 通信集成
class DeviceProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final DatabaseService _dbService = DatabaseService();
  final RuleEngine _ruleEngine = RuleEngine();

  List<Device> _devices = [];
  Map<int, List<DeviceProperty>> _properties = {}; // deviceId → properties
  Map<int, DateTime> _lastHeartbeat = {};           // deviceId → last heartbeat time
  Timer? _heartbeatTimer;

  List<Device> get devices => _devices;
  Map<int, List<DeviceProperty>> get properties => _properties;
  bool get mqttConnected => _mqttService.isConnected;

  /// 初始化：加载设备 + 连接 MQTT
  Future<void> init() async {
    await _loadDevices();
    await _connectMqtt();
    _startHeartbeatMonitor();
  }

  /// 从数据库加载设备和属性
  Future<void> _loadDevices() async {
    _devices = await _dbService.getAllDevices();
    for (final device in _devices) {
      _properties[device.id!] = await _dbService.getPropertiesByDevice(device.id!);
    }
    notifyListeners();
  }

  /// 连接 MQTT 并订阅设备主题
  Future<void> _connectMqtt() async {
    final connected = await _mqttService.connect();
    if (connected) {
      _subscribeAllDevices();
    }

    // 监听连接状态变化
    _mqttService.connectionStateStream.listen((connected) {
      if (connected) _subscribeAllDevices();
      notifyListeners();
    });
  }

  /// 订阅所有设备的状态和心跳主题
  void _subscribeAllDevices() {
    for (final device in _devices) {
      _subscribeDevice(device);
    }
  }

  /// 订阅单个设备
  void _subscribeDevice(Device device) {
    // 订阅状态上报
    _mqttService.subscribe(device.statusTopic, (topic, payload) {
      _onDeviceStatusReceived(device.id!, payload);
    });

    // 订阅心跳
    _mqttService.subscribe(device.heartbeatTopic, (topic, payload) {
      _onHeartbeatReceived(device.id!);
    });
  }

  /// 收到设备状态上报
  void _onDeviceStatusReceived(int deviceId, Map<String, dynamic> payload) {
    final props = _properties[deviceId];
    if (props == null) return;

    for (final prop in props) {
      if (payload.containsKey(prop.propertyKey)) {
        prop.setTypedValue(payload[prop.propertyKey]);
        // 更新数据库
        _dbService.updatePropertyValue(deviceId, prop.propertyKey, prop.value);
      }
    }

    // 标记在线
    final deviceIdx = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIdx >= 0 && !_devices[deviceIdx].isOnline) {
      _devices[deviceIdx].isOnline = true;
      _dbService.updateDevice(_devices[deviceIdx]);
    }

    // 触发联动规则评估
    _ruleEngine.onDevicePropertiesUpdated(deviceId, payload);

    notifyListeners();
  }

  /// 收到心跳
  void _onHeartbeatReceived(int deviceId) {
    _lastHeartbeat[deviceId] = DateTime.now();

    final deviceIdx = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIdx >= 0 && !_devices[deviceIdx].isOnline) {
      _devices[deviceIdx].isOnline = true;
      _dbService.updateDevice(_devices[deviceIdx]);
      notifyListeners();
    }
  }

  /// 心跳超时监控：定期检查设备在线状态
  void _startHeartbeatMonitor() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      bool changed = false;

      for (int i = 0; i < _devices.length; i++) {
        final device = _devices[i];
        final lastBeat = _lastHeartbeat[device.id];

        if (device.isOnline) {
          if (lastBeat != null &&
              now.difference(lastBeat).inSeconds > AppConstants.heartbeatTimeoutSeconds) {
            _devices[i].isOnline = false;
            _dbService.updateDevice(_devices[i]);
            changed = true;
          }
        }
      }

      if (changed) notifyListeners();
    });
  }

  /// 添加设备
  Future<void> addDevice(Device device) async {
    final id = await _dbService.insertDevice(device);
    final savedDevice = device.copyWith(id: id);

    // 保存默认属性
    final defaultProps = DeviceProperty.defaultsForDevice(id, device.deviceType);
    for (final prop in defaultProps) {
      await _dbService.insertProperty(prop);
    }

    _devices.insert(0, savedDevice);
    _properties[id] = defaultProps;

    // 订阅新设备
    _subscribeDevice(savedDevice);

    notifyListeners();
  }

  /// 删除设备
  Future<void> deleteDevice(int deviceId) async {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    _mqttService.unsubscribe(device.statusTopic);
    _mqttService.unsubscribe(device.heartbeatTopic);

    await _dbService.deleteDevice(deviceId);
    _devices.removeWhere((d) => d.id == deviceId);
    _properties.remove(deviceId);
    _lastHeartbeat.remove(deviceId);

    notifyListeners();
  }

  /// 向设备发送控制指令
  void controlDevice(int deviceId, String propertyKey, dynamic value) {
    final device = _devices.firstWhere((d) => d.id == deviceId);
    _mqttService.publish(device.setTopic, {propertyKey: value});

    // 乐观更新本地状态
    final props = _properties[deviceId];
    if (props != null) {
      final prop = props.firstWhere((p) => p.propertyKey == propertyKey,
          orElse: () => props.first);
      prop.setTypedValue(value);
      _dbService.updatePropertyValue(deviceId, propertyKey, value.toString());
      notifyListeners();
    }
  }

  /// 获取设备属性列表
  List<DeviceProperty> getProperties(int deviceId) {
    return _properties[deviceId] ?? [];
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _mqttService.disconnect();
    super.dispose();
  }
}
