import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/device_property.dart';

/// 属性控件工厂
/// 根据设备属性的数据类型和配置，动态生成对应的控件：
/// - bool → Switch 开关
/// - int/double + 有范围 → Slider 滑块
/// - int/double + 只读 → 数值显示
/// - string → 文本显示
class PropertyWidget extends StatelessWidget {
  final DeviceProperty property;
  final ValueChanged<dynamic>? onChanged;

  const PropertyWidget({
    super.key,
    required this.property,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 只读属性（如传感器数值）
    if (property.readOnly) {
      return _buildReadOnlyDisplay(theme);
    }

    switch (property.dataType) {
      case PropertyDataType.bool_:
        return _buildSwitch(theme);
      case PropertyDataType.int_:
      case PropertyDataType.double_:
        if (property.minValue != null && property.maxValue != null) {
          return _buildSlider(theme);
        }
        return _buildNumericInput(theme);
      case PropertyDataType.string_:
        return _buildTextDisplay(theme);
    }
  }

  /// 开关控件
  Widget _buildSwitch(ThemeData theme) {
    final isOn = property.typedValue == true;
    return ListTile(
      leading: Icon(
        isOn ? Icons.lightbulb : Icons.lightbulb_outline,
        color: isOn ? Colors.amber : Colors.grey,
        size: 28,
      ),
      title: Text(property.label, style: theme.textTheme.bodyLarge),
      trailing: Switch(
        value: isOn,
        onChanged: (val) => onChanged?.call(val),
      ),
    );
  }

  /// 滑块控件
  Widget _buildSlider(ThemeData theme) {
    final currentValue = (property.typedValue as num).toDouble();
    final min = property.minValue!;
    final max = property.maxValue!;
    final isInt = property.dataType == PropertyDataType.int_;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(property.label, style: theme.textTheme.bodyLarge),
              Text(
                '${isInt ? currentValue.toInt() : currentValue.toStringAsFixed(1)}${property.unit ?? ''}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            divisions: isInt ? (max - min).toInt() : null,
            onChanged: (val) => onChanged?.call(isInt ? val.toInt() : val),
          ),
        ],
      ),
    );
  }

  /// 只读数值显示（传感器等）
  Widget _buildReadOnlyDisplay(ThemeData theme) {
    final displayValue = property.value.isEmpty ? '--' : property.value;
    return ListTile(
      leading: Icon(
        _getIconForProperty(property.propertyKey),
        color: theme.colorScheme.primary,
        size: 28,
      ),
      title: Text(property.label, style: theme.textTheme.bodyLarge),
      trailing: Text(
        '$displayValue${property.unit ?? ''}',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// 数值输入（无范围限制时）
  Widget _buildNumericInput(ThemeData theme) {
    return ListTile(
      title: Text(property.label, style: theme.textTheme.bodyLarge),
      trailing: SizedBox(
        width: 100,
        child: TextField(
          controller: TextEditingController(text: property.value),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: property.unit,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (val) => onChanged?.call(val),
        ),
      ),
    );
  }

  /// 文本显示
  Widget _buildTextDisplay(ThemeData theme) {
    return ListTile(
      title: Text(property.label, style: theme.textTheme.bodyLarge),
      trailing: Text(
        property.value.isEmpty ? '--' : property.value,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 根据属性键获取图标
  IconData _getIconForProperty(String key) {
    switch (key) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop_outlined;
      case 'brightness':
        return Icons.brightness_6;
      case 'speed':
        return Icons.speed;
      default:
        return Icons.sensors;
    }
  }
}
