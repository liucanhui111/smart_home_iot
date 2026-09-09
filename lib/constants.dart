/// 应用常量配置
/// 修改此处即可适配不同的 MQTT Broker 和环境

class AppConstants {
  // ══════════════════════════════════════════
  // MQTT Broker 配置
  // ══════════════════════════════════════════
  static const String mqttBrokerIp = '192.168.1.100'; // 改为你的 Broker IP
  static const int mqttBrokerPort = 1883;
  static const String mqttUsername = '';                // 留空表示无认证
  static const String mqttPassword = '';
  static const String mqttClientIdPrefix = 'smart_home_app_';
  static const int mqttKeepAliveSeconds = 30;
  static const int mqttReconnectDelaySeconds = 5;

  // ══════════════════════════════════════════
  // 设备心跳 & 超时
  // ══════════════════════════════════════════
  static const int heartbeatTimeoutSeconds = 60; // 超过此秒数视为离线

  // ══════════════════════════════════════════
  // 数据库
  // ══════════════════════════════════════════
  static const String dbName = 'smart_home.db';
  static const int dbVersion = 1;

  // ══════════════════════════════════════════
  // MQTT 主题约定
  // ══════════════════════════════════════════
  // 设备属性上报: {topicPrefix}/status
  // 设备控制下发: {topicPrefix}/set
  // 设备心跳:     {topicPrefix}/heartbeat
  static const String topicSuffixStatus = 'status';
  static const String topicSuffixSet = 'set';
  static const String topicSuffixHeartbeat = 'heartbeat';
}

/// 设备类型枚举
enum DeviceType {
  light('灯', '💡'),
  switch_('开关', '🔌'),
  sensor('传感器', '🌡️'),
  fan('风扇', '🌀'),
  thermostat('温控器', '❄️'),
  other('其他', '📱');

  final String label;
  final String emoji;
  const DeviceType(this.label, this.emoji);

  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.other,
    );
  }
}

/// 属性数据类型枚举
enum PropertyDataType {
  bool_('bool'),
  int_('int'),
  double_('double'),
  string_('string');

  final String label;
  const PropertyDataType(this.label);

  static PropertyDataType fromString(String value) {
    return PropertyDataType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PropertyDataType.string_,
    );
  }
}

/// 规则条件枚举
enum RuleCondition {
  eq('等于', '=='),
  gt('大于', '>'),
  lt('小于', '<'),
  gte('大于等于', '>='),
  lte('小于等于', '<=');

  final String label;
  final String symbol;
  const RuleCondition(this.label, this.symbol);

  static RuleCondition fromString(String value) {
    return RuleCondition.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RuleCondition.eq,
    );
  }

  /// 评估条件是否满足
  bool evaluate(dynamic actual, dynamic threshold) {
    final a = double.tryParse(actual.toString()) ?? 0;
    final t = double.tryParse(threshold.toString()) ?? 0;
    switch (this) {
      case RuleCondition.eq:
        return actual.toString() == threshold.toString();
      case RuleCondition.gt:
        return a > t;
      case RuleCondition.lt:
        return a < t;
      case RuleCondition.gte:
        return a >= t;
      case RuleCondition.lte:
        return a <= t;
    }
  }
}
