import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';

/// 添加设备页面
/// 输入设备名称、MQTT 主题前缀、选择设备类型
class DeviceAddScreen extends StatefulWidget {
  const DeviceAddScreen({super.key});

  @override
  State<DeviceAddScreen> createState() => _DeviceAddScreenState();
}

class _DeviceAddScreenState extends State<DeviceAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  DeviceType _selectedType = DeviceType.light;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加设备'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 设备类型选择
              Text('设备类型', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DeviceType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text('${type.emoji} ${type.label}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: theme.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 设备名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '设备名称',
                  hintText: '例如：客厅主灯',
                  prefixIcon: Icon(Icons.devices),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return '请输入设备名称';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // MQTT 主题前缀
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'MQTT 主题前缀',
                  hintText: '例如：home/livingroom/light1',
                  prefixIcon: Icon(Icons.topic),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return '请输入主题前缀';
                  if (val.contains(' ')) return '主题不能包含空格';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // 主题格式说明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('主题格式约定：', style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      '• 状态上报: {前缀}/status\n'
                      '• 控制下发: {前缀}/set\n'
                      '• 心跳上报: {前缀}/heartbeat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 提交按钮
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('添加设备'),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final device = Device(
      name: _nameController.text.trim(),
      topicPrefix: _topicController.text.trim(),
      deviceType: _selectedType,
    );

    context.read<DeviceProvider>().addDevice(device);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加设备: ${device.name}')),
    );

    Navigator.pop(context);
  }
}
