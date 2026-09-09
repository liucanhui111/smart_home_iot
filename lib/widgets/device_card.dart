import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/device.dart';

/// 设备卡片组件
/// 展示设备名称、类型图标、在线状态
class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = device.isOnline;

    return Card(
      elevation: isOnline ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isOnline
          ? theme.colorScheme.surface
          : theme.colorScheme.surface.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 设备类型图标
              Text(
                device.deviceType.emoji,
                style: TextStyle(
                  fontSize: 36,
                  color: isOnline ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              // 设备名称
              Text(
                device.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOnline ? null : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // 在线状态指示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? '在线' : '离线',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isOnline ? Colors.green : Colors.grey,
                      fontSize: 11,
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
