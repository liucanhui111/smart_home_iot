import '../constants.dart';

/// 设备属性模型
/// 代表设备的一个可读/可写属性，如开关状态、亮度、温度等
class DeviceProperty {
  final int? id;
  final int deviceId;
  final String propertyKey;      // 属性键，如 "power", "brightness", "temperature"
  String value;                  // 当前值（统一用字符串存储，运行时转换）
  final PropertyDataType dataType;
  final String label;            // 显示名称
  final bool readOnly;           // 是否只读（如传感器数值）
  final String? unit;            // 单位（如 "°C", "%"）
  final double? minValue;        // 滑块最小值
  final double? maxValue;        // 滑块最大值

  DeviceProperty({
    this.id,
    required this.deviceId,
    required this.propertyKey,
    this.value = '',
    required this.dataType,
    this.label = '',
    this.readOnly = false,
    this.unit,
    this.minValue,
    this.maxValue,
  });

  factory DeviceProperty.fromMap(Map<String, dynamic> map) {
    return DeviceProperty(
      id: map['id'] as int?,
      deviceId: map['deviceId'] as int,
      propertyKey: map['propertyKey'] as String,
      value: map['value'] as String? ?? '',
      dataType: PropertyDataType.fromString(map['dataType'] as String),
      label: map['label'] as String? ?? '',
      readOnly: (map['readOnly'] as int? ?? 0) == 1,
      unit: map['unit'] as String?,
      minValue: (map['minValue'] as num?)?.toDouble(),
      maxValue: (map['maxValue'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'deviceId': deviceId,
      'propertyKey': propertyKey,
      'value': value,
      'dataType': dataType.name,
      'label': label.isEmpty ? propertyKey : label,
      'readOnly': readOnly ? 1 : 0,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  /// 获取当前值的原生类型
  dynamic get typedValue {
    switch (dataType) {
      case PropertyDataType.bool_:
        return value == 'true' || value == '1';
      case PropertyDataType.int_:
        return int.tryParse(value) ?? 0;
      case PropertyDataType.double_:
        return double.tryParse(value) ?? 0.0;
      case PropertyDataType.string_:
        return value;
    }
  }

  /// 设置值（自动转为字符串）
  void setTypedValue(dynamic v) {
    value = v.toString();
  }

  /// 根据设备类型返回默认属性列表
  static List<DeviceProperty> defaultsForDevice(int deviceId, DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'power',
            dataType: PropertyDataType.bool_,
            label: '开关',
            value: 'false',
          ),
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'brightness',
            dataType: PropertyDataType.int_,
            label: '亮度',
            value: '100',
            unit: '%',
            minValue: 0,
            maxValue: 100,
          ),
        ];
      case DeviceType.switch_:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'power',
            dataType: PropertyDataType.bool_,
            label: '开关',
            value: 'false',
          ),
        ];
      case DeviceType.sensor:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'temperature',
            dataType: PropertyDataType.double_,
            label: '温度',
            readOnly: true,
            unit: '°C',
          ),
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'humidity',
            dataType: PropertyDataType.double_,
            label: '湿度',
            readOnly: true,
            unit: '%',
          ),
        ];
      case DeviceType.fan:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'power',
            dataType: PropertyDataType.bool_,
            label: '开关',
            value: 'false',
          ),
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'speed',
            dataType: PropertyDataType.int_,
            label: '风速',
            value: '1',
            minValue: 1,
            maxValue: 5,
          ),
        ];
      case DeviceType.thermostat:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'power',
            dataType: PropertyDataType.bool_,
            label: '开关',
            value: 'false',
          ),
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'targetTemp',
            dataType: PropertyDataType.double_,
            label: '目标温度',
            value: '24',
            unit: '°C',
            minValue: 16,
            maxValue: 32,
          ),
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'currentTemp',
            dataType: PropertyDataType.double_,
            label: '当前温度',
            readOnly: true,
            unit: '°C',
          ),
        ];
      case DeviceType.other:
        return [
          DeviceProperty(
            deviceId: deviceId,
            propertyKey: 'power',
            dataType: PropertyDataType.bool_,
            label: '开关',
            value: 'false',
          ),
        ];
    }
  }
}
