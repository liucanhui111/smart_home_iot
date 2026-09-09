import 'package:flutter/foundation.dart';
import '../models/automation_rule.dart';
import '../services/database_service.dart';
import '../services/rule_engine.dart';

/// 联动规则状态管理 Provider
class RuleProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final RuleEngine _ruleEngine = RuleEngine();

  List<AutomationRule> _rules = [];
  List<AutomationRule> get rules => _rules;

  /// 加载所有规则
  Future<void> loadRules() async {
    _rules = await _dbService.getAllRules();
    notifyListeners();
  }

  /// 添加规则
  Future<void> addRule(AutomationRule rule) async {
    final id = await _dbService.insertRule(rule);
    final saved = rule.copyWith(id: id);
    _rules.insert(0, saved);
    await _ruleEngine.refreshRules();
    notifyListeners();
  }

  /// 更新规则
  Future<void> updateRule(AutomationRule rule) async {
    await _dbService.updateRule(rule);
    final idx = _rules.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) _rules[idx] = rule;
    await _ruleEngine.refreshRules();
    notifyListeners();
  }

  /// 删除规则
  Future<void> deleteRule(int id) async {
    await _dbService.deleteRule(id);
    _rules.removeWhere((r) => r.id == id);
    await _ruleEngine.refreshRules();
    notifyListeners();
  }

  /// 切换规则启用/禁用
  Future<void> toggleRule(int id) async {
    final rule = _rules.firstWhere((r) => r.id == id);
    rule.enabled = !rule.enabled;
    await _dbService.updateRule(rule);
    await _ruleEngine.refreshRules();
    notifyListeners();
  }

  /// 测试执行规则
  Future<void> testRule(AutomationRule rule) async {
    await _ruleEngine.testRule(rule);
  }
}
