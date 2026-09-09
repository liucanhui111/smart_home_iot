import '../constants.dart';

/// 设备模型
class Device {
  final int? id;
  final String name;
  final String topicPrefix;       // MQTT 主题前缀，如 "home/livingroom/light1"
  final DeviceType deviceType;
  bool isOnline;
  final String iconName;          // 图标标识（Material icon name）
  final DateTime createdAt;

  Device({
    this.id,
    required this.name,
    required this.topicPrefix,
    required this.deviceType,
    this.isOnline = false,
    this.iconName = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从数据库 Map 构造
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as int?,
      name: map['name'] as String,
      topicPrefix: map['topicPrefix'] as String,
      deviceType: DeviceType.fromString(map['deviceType'] as String),
      isOnline: (map['isOnline'] as int? ?? 0) == 1,
      iconName: map['iconName'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'topicPrefix': topicPrefix,
      'deviceType': deviceType.name,
      'isOnline': isOnline ? 1 : 0,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 获取完整状态主题
  String get statusTopic => '$topicPrefix/status';
  String get setTopic => '$topicPrefix/set';
  String get heartbeatTopic => '$topicPrefix/heartbeat';

  Device copyWith({
    int? id,
    String? name,
    String? topicPrefix,
    DeviceType? deviceType,
    bool? isOnline,
    String? iconName,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      topicPrefix: topicPrefix ?? this.topicPrefix,
      deviceType: deviceType ?? this.deviceType,
      isOnline: isOnline ?? this.isOnline,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
    );
  }
}
