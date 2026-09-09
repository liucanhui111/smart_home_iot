import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/automation_rule.dart';
import '../models/device_property.dart';
import 'mqtt_service.dart';
import 'database_service.dart';

/// 联动规则引擎
/// 监听设备属性变化，匹配规则并执行动作
class RuleEngine {
  static final RuleEngine _instance = RuleEngine._internal();
  factory RuleEngine() => _instance;
  RuleEngine._internal();

  final MqttService _mqttService = MqttService();
  final DatabaseService _dbService = DatabaseService();

  // 缓存已启用的规则
  List<AutomationRule> _activeRules = [];

  /// 初始化：加载所有已启用的规则
  Future<void> init() async {
    await refreshRules();
    debugPrint('[RuleEngine] 初始化完成，已加载 ${_activeRules.length} 条规则');
  }

  /// 刷新规则缓存
  Future<void> refreshRules() async {
    final allRules = await _dbService.getAllRules();
    _activeRules = allRules.where((r) => r.enabled).toList();
  }

  /// 当收到设备属性上报时调用
  /// [deviceId] 属性所属设备的 ID
  /// [properties] 上报的属性键值对
  Future<void> onDevicePropertiesUpdated(
    int deviceId,
    Map<String, dynamic> properties,
  ) async {
    for (final rule in _activeRules) {
      if (rule.triggerDeviceId != deviceId) continue;
      if (!properties.containsKey(rule.triggerPropertyKey)) continue;

      final actualValue = properties[rule.triggerPropertyKey];
      final conditionMet = rule.condition.evaluate(actualValue, rule.threshold);

      if (conditionMet) {
        debugPrint('[RuleEngine] 规则触发: ${rule.name}');
        await _executeAction(rule);
      }
    }
  }

  /// 执行规则动作：向目标设备发布控制指令
  Future<void> _executeAction(AutomationRule rule) async {
    final targetDevice = await _dbService.getDeviceById(rule.actionDeviceId);
    if (targetDevice == null) {
      debugPrint('[RuleEngine] 目标设备不存在: ${rule.actionDeviceId}');
      return;
    }

    final payload = {rule.actionPropertyKey: rule.actionValue};
    _mqttService.publish(targetDevice.setTopic, payload);
    debugPrint('[RuleEngine] 执行动作: ${targetDevice.name} → ${rule.actionPropertyKey}=${rule.actionValue}');

    // 更新本地属性值
    await _dbService.updatePropertyValue(
      rule.actionDeviceId,
      rule.actionPropertyKey,
      rule.actionValue,
    );
  }

  /// 手动触发规则测试（不检查条件，直接执行动作）
  Future<void> testRule(AutomationRule rule) async {
    await _executeAction(rule);
  }
}
