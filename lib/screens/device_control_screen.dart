import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/device.dart';
import '../models/device_property.dart';
import '../providers/device_provider.dart';
import '../widgets/property_widget.dart';

/// 设备控制页面
/// 根据设备类型动态生成控制控件（开关、滑块、数值显示）
class DeviceControlScreen extends StatelessWidget {
  final Device device;

  const DeviceControlScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        centerTitle: true,
        actions: [
          // 在线状态指示
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    device.isOnline ? '在线' : '离线',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, provider, _) {
          final properties = provider.getProperties(device.id!);

          if (properties.isEmpty) {
            return const Center(child: Text('该设备暂无属性'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 设备信息卡片
              _buildDeviceInfoCard(theme),
              const SizedBox(height: 8),
              // 设备类型标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      device.deviceType.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${device.deviceType.label}控制',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // 动态属性控件
              ...properties.map((prop) => _buildPropertyCard(theme, provider, prop)),
              const SizedBox(height: 16),
              // 主题信息
              _buildTopicInfo(theme),
            ],
          );
        },
      ),
    );
  }

  /// 设备信息卡片
  Widget _buildDeviceInfoCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 大图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: device.isOnline
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  device.deviceType.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '类型: ${device.deviceType.label}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 属性控件卡片
  Widget _buildPropertyCard(ThemeData theme, DeviceProvider provider, DeviceProperty prop) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: PropertyWidget(
        property: prop,
        onChanged: (value) {
          provider.controlDevice(device.id!, prop.propertyKey, value);
        },
      ),
    );
  }

  /// 主题信息
  Widget _buildTopicInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MQTT 主题', style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 4),
            Text(
              '状态: ${device.statusTopic}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Colors.grey[600],
              ),
            ),
            Text(
              '控制: ${device.setTopic}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
