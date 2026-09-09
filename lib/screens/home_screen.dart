import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/device_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/rule_provider.dart';
import '../widgets/device_card.dart';
import 'device_add_screen.dart';
import 'device_control_screen.dart';
import 'automation_list_screen.dart';

/// 首页
/// 展示设备网格 + 底部导航栏（设备 / 联动规则 / 设置）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 延迟初始化，避免在 build 中调用
    Future.microtask(() {
      context.read<DeviceProvider>().init();
      context.read<RuleProvider>().loadRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  _DeviceGridPage(),
                  AutomationListScreen(),
                  _SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '设备',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '联动',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _navigateToAddDevice(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// 顶部状态栏
  Widget _buildHeader(ThemeData theme) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '智能家居',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // MQTT 连接状态指示灯
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: provider.mqttConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.mqttConnected ? '已连接 Broker' : '未连接',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: provider.mqttConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${provider.devices.where((d) => d.isOnline).length}/${provider.devices.length} 在线',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddDevice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeviceAddScreen()),
    );
  }
}

/// 设备网格页面
class _DeviceGridPage extends StatelessWidget {
  const _DeviceGridPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        if (provider.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '还没有设备',
                  style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角 + 添加你的第一个设备',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: provider.devices.length,
          itemBuilder: (context, index) {
            final device = provider.devices[index];
            return DeviceCard(
              device: device,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeviceControlScreen(device: device),
                  ),
                );
              },
              onLongPress: () => _showDeleteDialog(context, provider, device.id!),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, DeviceProvider provider, int deviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除设备'),
        content: const Text('确定要删除这个设备吗？相关的联动规则也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDevice(deviceId);
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

/// 设置页面
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // MQTT 配置区
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('MQTT Broker'),
                subtitle: Text(
                  '${AppConstants.mqttBrokerIp}:${AppConstants.mqttBrokerPort}',
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _showBrokerInfo(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 主题设置
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('深色模式'),
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 关于
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('本地智能家居 v1.0.0\n纯本地 MQTT 通信，无云依赖'),
          ),
        ),
      ],
    );
  }

  void _showBrokerInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('MQTT Broker 配置'),
        content: Text(
          '当前连接: ${AppConstants.mqttBrokerIp}:${AppConstants.mqttBrokerPort}\n\n'
          '修改方法: 编辑 lib/constants.dart 中的\n'
          'mqttBrokerIp 和 mqttBrokerPort',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
