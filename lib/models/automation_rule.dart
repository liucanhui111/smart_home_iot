import '../constants.dart';

/// 联动规则模型
/// 格式：当 [触发设备.属性] [条件] [阈值] 时，执行 [目标设备.属性] = [目标值]
class AutomationRule {
  final int? id;
  final String name;
  bool enabled;

  // 触发条件
  final int triggerDeviceId;
  final String triggerPropertyKey;
  final RuleCondition condition;
  final String threshold;           // 阈值（字符串，运行时解析）

  // 执行动作
  final int actionDeviceId;
  final String actionPropertyKey;
  final String actionValue;         // 目标值

  AutomationRule({
    this.id,
    required this.name,
    this.enabled = true,
    required this.triggerDeviceId,
    required this.triggerPropertyKey,
    required this.condition,
    required this.threshold,
    required this.actionDeviceId,
    required this.actionPropertyKey,
    required this.actionValue,
  });

  factory AutomationRule.fromMap(Map<String, dynamic> map) {
    return AutomationRule(
      id: map['id'] as int?,
      name: map['name'] as String,
      enabled: (map['enabled'] as int? ?? 1) == 1,
      triggerDeviceId: map['triggerDeviceId'] as int,
      triggerPropertyKey: map['triggerPropertyKey'] as String,
      condition: RuleCondition.fromString(map['condition'] as String),
      threshold: map['threshold'] as String? ?? '',
      actionDeviceId: map['actionDeviceId'] as int,
      actionPropertyKey: map['actionPropertyKey'] as String,
      actionValue: map['actionValue'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'enabled': enabled ? 1 : 0,
      'triggerDeviceId': triggerDeviceId,
      'triggerPropertyKey': triggerPropertyKey,
      'condition': condition.name,
      'threshold': threshold,
      'actionDeviceId': actionDeviceId,
      'actionPropertyKey': actionPropertyKey,
      'actionValue': actionValue,
    };
  }

  AutomationRule copyWith({
    int? id,
    String? name,
    bool? enabled,
    int? triggerDeviceId,
    String? triggerPropertyKey,
    RuleCondition? condition,
    String? threshold,
    int? actionDeviceId,
    String? actionPropertyKey,
    String? actionValue,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      triggerDeviceId: triggerDeviceId ?? this.triggerDeviceId,
      triggerPropertyKey: triggerPropertyKey ?? this.triggerPropertyKey,
      condition: condition ?? this.condition,
      threshold: threshold ?? this.threshold,
      actionDeviceId: actionDeviceId ?? this.actionDeviceId,
      actionPropertyKey: actionPropertyKey ?? this.actionPropertyKey,
      actionValue: actionValue ?? this.actionValue,
    );
  }
}
