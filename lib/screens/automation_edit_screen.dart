import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/automation_rule.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../providers/rule_provider.dart';

/// 联动规则编辑页面
/// 支持新建和编辑联动规则
class AutomationEditScreen extends StatefulWidget {
  final AutomationRule? rule; // null 表示新建

  const AutomationEditScreen({super.key, this.rule});

  @override
  State<AutomationEditScreen> createState() => _AutomationEditScreenState();
}

class _AutomationEditScreenState extends State<AutomationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _actionValueController = TextEditingController();

  // 触发条件
  Device? _triggerDevice;
  String? _triggerPropertyKey;
  RuleCondition _condition = RuleCondition.gt;

  // 执行动作
  Device? _actionDevice;
  String? _actionPropertyKey;

  bool get isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.rule!.name;
      _thresholdController.text = widget.rule!.threshold;
      _actionValueController.text = widget.rule!.actionValue;
      _condition = widget.rule!.condition;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isEditing) {
      final devices = context.read<DeviceProvider>().devices;
      _triggerDevice = devices.where((d) => d.id == widget.rule!.triggerDeviceId).firstOrNull;
      _actionDevice = devices.where((d) => d.id == widget.rule!.actionDeviceId).firstOrNull;
      _triggerPropertyKey = widget.rule!.triggerPropertyKey;
      _actionPropertyKey = widget.rule!.actionPropertyKey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _thresholdController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devices = context.watch<DeviceProvider>().devices;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑规则' : '新建规则'),
        centerTitle: true,
      ),
      body: devices.isEmpty
          ? const Center(child: Text('请先添加至少两个设备'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 规则名称
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '规则名称',
                        hintText: '例如：温度过高时开风扇',
                        prefixIcon: Icon(Icons.label_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? '请输入规则名称' : null,
                    ),
                    const SizedBox(height: 24),

                    // ── 触发条件区 ──
                    _buildSectionHeader(theme, '当...', Icons.flash_on),
                    const SizedBox(height: 8),

                    // 选择触发设备
                    _buildDeviceDropdown(
                      label: '触发设备',
                      value: _triggerDevice,
                      devices: devices,
                      onChanged: (d) => setState(() {
                        _triggerDevice = d;
                        _triggerPropertyKey = null;
                      }),
                    ),
                    const SizedBox(height: 12),

                    // 选择触发属性
                    if (_triggerDevice != null)
                      _buildPropertyDropdown(
                        label: '触发属性',
                        deviceId: _triggerDevice!.id!,
                        value: _triggerPropertyKey,
                        onChanged: (val) => setState(() => _triggerPropertyKey = val),
                      ),
                    const SizedBox(height: 12),

                    // 条件 + 阈值
                    Row(
                      children: [
                        // 条件选择
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<RuleCondition>(
                            value: _condition,
                            decoration: const InputDecoration(
                              labelText: '条件',
                              border: OutlineInputBorder(),
                            ),
                            items: RuleCondition.values.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.symbol} ${c.label}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _condition = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 阈值
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _thresholdController,
                            decoration: const InputDecoration(
                              labelText: '阈值',
                              hintText: '例如: 30 或 true',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? '请输入阈值' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── 执行动作区 ──
                    _buildSectionHeader(theme, '就执行...', Icons.play_arrow),
                    const SizedBox(height: 8),

                    // 选择执行设备
                    _buildDeviceDropdown(
                      label: '执行设备',
                      value: _actionDevice,
                      devices: devices,
                      onChanged: (d) => setState(() {
                        _actionDevice = d;
                        _actionPropertyKey = null;
                      }),
                    ),
                    const SizedBox(height: 12),

                    // 选择执行属性
                    if (_actionDevice != null)
                      _buildPropertyDropdown(
                        label: '执行属性',
                        deviceId: _actionDevice!.id!,
                        value: _actionPropertyKey,
                        onChanged: (val) => setState(() => _actionPropertyKey = val),
                      ),
                    const SizedBox(height: 12),

                    // 执行值
                    TextFormField(
                      controller: _actionValueController,
                      decoration: const InputDecoration(
                        labelText: '执行值',
                        hintText: '例如: false 或 3',
                        prefixIcon: Icon(Icons.data_object),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? '请输入执行值' : null,
                    ),
                    const SizedBox(height: 32),

                    // 保存按钮
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? '保存修改' : '创建规则'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 区段标题
  Widget _buildSectionHeader(ThemeData theme, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// 设备下拉框
  Widget _buildDeviceDropdown({
    required String label,
    required Device? value,
    required List<Device> devices,
    required ValueChanged<Device?> onChanged,
  }) {
    return DropdownButtonFormField<Device>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: devices.map((d) {
        return DropdownMenuItem(
          value: d,
          child: Text('${d.deviceType.emoji} ${d.name}'),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? '请选择设备' : null,
    );
  }

  /// 属性下拉框
  Widget _buildPropertyDropdown({
    required String label,
    required int deviceId,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final props = provider.getProperties(deviceId);
        if (props.isEmpty) {
          return const Text('该设备暂无属性', style: TextStyle(color: Colors.grey));
        }

        // 确保 value 在列表中
        final validValue = props.any((p) => p.propertyKey == value) ? value : null;

        return DropdownButtonFormField<String>(
          value: validValue,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: props.map((p) {
            return DropdownMenuItem(
              value: p.propertyKey,
              child: Text('${p.label} (${p.propertyKey})'),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? '请选择属性' : null,
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_triggerDevice == null || _actionDevice == null) return;
    if (_triggerPropertyKey == null || _actionPropertyKey == null) return;

    final rule = AutomationRule(
      id: widget.rule?.id,
      name: _nameController.text.trim(),
      enabled: widget.rule?.enabled ?? true,
      triggerDeviceId: _triggerDevice!.id!,
      triggerPropertyKey: _triggerPropertyKey!,
      condition: _condition,
      threshold: _thresholdController.text.trim(),
      actionDeviceId: _actionDevice!.id!,
      actionPropertyKey: _actionPropertyKey!,
      actionValue: _actionValueController.text.trim(),
    );

    final ruleProvider = context.read<RuleProvider>();
    if (isEditing) {
      ruleProvider.updateRule(rule);
    } else {
      ruleProvider.addRule(rule);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEditing ? '规则已更新' : '规则已创建')),
    );

    Navigator.pop(context);
  }
}
