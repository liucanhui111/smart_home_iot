import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rule_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/rule_condition_tile.dart';
import 'automation_edit_screen.dart';

/// 联动规则列表页面
class AutomationListScreen extends StatelessWidget {
  const AutomationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 页面标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                '联动规则',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _navigateToEdit(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建'),
              ),
            ],
          ),
        ),
        // 规则列表
        Expanded(
          child: Consumer2<RuleProvider, DeviceProvider>(
            builder: (context, ruleProvider, deviceProvider, _) {
              if (ruleProvider.rules.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '还没有联动规则',
                        style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '创建规则让设备自动联动',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: ruleProvider.rules.length,
                itemBuilder: (context, index) {
                  final rule = ruleProvider.rules[index];
                  final triggerDevice = deviceProvider.devices
                      .where((d) => d.id == rule.triggerDeviceId)
                      .firstOrNull;
                  final actionDevice = deviceProvider.devices
                      .where((d) => d.id == rule.actionDeviceId)
                      .firstOrNull;

                  return RuleConditionTile(
                    rule: rule,
                    triggerDevice: triggerDevice,
                    actionDevice: actionDevice,
                    onToggle: (_) => ruleProvider.toggleRule(rule.id!),
                    onTap: () => _navigateToEdit(context, rule),
                    onDelete: () => _confirmDelete(context, ruleProvider, rule.id!, rule.name),
                    onTest: () {
                      ruleProvider.testRule(rule);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已测试执行: ${rule.name}')),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToEdit(BuildContext context, dynamic rule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutomationEditScreen(rule: rule),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RuleProvider provider, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除规则 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRule(id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
