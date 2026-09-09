import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/automation_rule.dart';
import '../models/device.dart';

/// 规则条件展示组件
/// 以卡片形式展示一条联动规则的摘要信息
class RuleConditionTile extends StatelessWidget {
  final AutomationRule rule;
  final Device? triggerDevice;
  final Device? actionDevice;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTest;

  const RuleConditionTile({
    super.key,
    required this.rule,
    this.triggerDevice,
    this.actionDevice,
    this.onToggle,
    this.onTap,
    this.onDelete,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final triggerName = triggerDevice?.name ?? '设备#${rule.triggerDeviceId}';
    final actionName = actionDevice?.name ?? '设备#${rule.actionDeviceId}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行：规则名 + 启用开关
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: rule.enabled ? theme.colorScheme.primary : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rule.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: rule.enabled,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 规则描述
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // 触发条件
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('当', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '$triggerName.${rule.triggerPropertyKey}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${rule.condition.symbol} ${rule.threshold}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 箭头
                    Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                    // 执行动作
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('执行', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            '$actionName.${rule.actionPropertyKey}',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '= ${rule.actionValue}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('测试'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('删除'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
