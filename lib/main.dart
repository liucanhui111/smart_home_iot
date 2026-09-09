import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/device_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/rule_provider.dart';

/// 应用入口
/// 初始化 Provider 状态管理，启动 App
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 预加载主题偏好
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => RuleProvider()),
      ],
      child: const SmartHomeApp(),
    ),
  );
}
