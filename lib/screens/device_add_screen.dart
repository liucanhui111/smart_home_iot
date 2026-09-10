import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../constants.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../services/wifi_scan_service.dart';
import '../services/device_discovery_service.dart';

/// 添加设备页面（3步引导式）
/// 步骤1：连接WiFi
/// 步骤2：扫描发现设备
/// 步骤3：确认设备信息
class DeviceAddScreen extends StatefulWidget {
  const DeviceAddScreen({super.key});

  @override
  State<DeviceAddScreen> createState() => _DeviceAddScreenState();
}

class _DeviceAddScreenState extends State<DeviceAddScreen> {
  final PageController _pageController = PageController();
  final WifiScanService _wifiService = WifiScanService();
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();

  // 步骤1：WiFi 相关
  List<WiFiAccessPoint> _wifiList = [];
  WiFiAccessPoint? _selectedWifi;
  final _wifiPasswordController = TextEditingController();
  bool _scanningWifi = false;
  bool _connectingWifi = false;
  WifiConnectionInfo? _currentConnection;

  // 步骤2：设备发现相关
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _scanningDevices = false;
  DiscoveredDevice? _selectedDevice;

  // 步骤3：设备信息
  final _deviceNameController = TextEditingController();
  final _topicController = TextEditingController();
  DeviceType _selectedType = DeviceType.light;
  String _selectedRoom = '客厅';
  int _currentStep = 0;

  final List<String> _rooms = ['客厅', '卧室', '厨房', '卫生间', '阳台', '书房', '走廊', '其他'];

  @override
  void initState() {
    super.initState();
    _checkCurrentWifi();
  }

  @override
  void dispose() {
    _wifiPasswordController.dispose();
    _deviceNameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  /// 检查当前 WiFi 连接状态
  Future<void> _checkCurrentWifi() async {
    final info = await _wifiService.getCurrentConnection();
    setState(() => _currentConnection = info);
    if (info.isConnected) {
      // 已连WiFi，直接跳到扫描步骤
      _goToStep(1);
      _startDeviceScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加设备'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildWifiStep(theme),
          _buildScanStep(theme),
          _buildConfirmStep(theme),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 步骤1：WiFi 连接
  // ══════════════════════════════════════════

  Widget _buildWifiStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 步骤标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('1', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text('连接 WiFi', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '确保手机和 ESP32 设备连接同一个 WiFi',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // 当前连接状态
          if (_currentConnection != null && _currentConnection!.isConnected)
            Card(
              color: Colors.green.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.wifi, color: Colors.green),
                title: Text('已连接: ${_currentConnection!.ssid}'),
                subtitle: Text('IP: ${_currentConnection!.ip}'),
                trailing: TextButton(
                  onPressed: () => _goToStep(1),
                  child: const Text('下一步'),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // 扫描按钮
          OutlinedButton.icon(
            onPressed: _scanningWifi ? null : _scanWifi,
            icon: _scanningWifi
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_find),
            label: Text(_scanningWifi ? '扫描中...' : '扫描附近 WiFi'),
          ),
          const SizedBox(height: 12),

          // WiFi 列表
          Expanded(
            child: _wifiList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('点击上方按钮扫描 WiFi', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _wifiList.length,
                    itemBuilder: (context, index) {
                      final ap = _wifiList[index];
                      final isSelected = _selectedWifi?.ssid == ap.ssid;
                      final signalIcon = _getSignalIcon(ap.level);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        color: isSelected ? theme.colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: Icon(signalIcon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
                          title: Text(ap.ssid, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text('${ap.level} dBm • ${ap.capabilities.contains("WPA") ? "加密" : "开放"}'),
                          trailing: isSelected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
                          onTap: () => setState(() => _selectedWifi = ap),
                        ),
                      );
                    },
                  ),
          ),

          // 密码输入 + 连接按钮
          if (_selectedWifi != null) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _wifiPasswordController,
              decoration: InputDecoration(
                labelText: 'WiFi 密码',
                hintText: '输入 ${_selectedWifi!.ssid} 的密码',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility_off),
                  onPressed: () {},
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _connectingWifi ? null : _connectWifi,
              icon: _connectingWifi
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.wifi),
              label: Text(_connectingWifi ? '连接中...' : '连接 WiFi'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 步骤2：设备扫描
  // ══════════════════════════════════════════

  Widget _buildScanStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 步骤标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('2', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text('扫描设备', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '正在搜索局域网内的 ESP32 设备...',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // 当前 WiFi 信息
          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi, color: Colors.blue),
              title: Text(_currentConnection?.ssid ?? '未连接'),
              subtitle: Text('IP: ${_currentConnection?.ip ?? "---"}'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _startDeviceScan,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 扫描状态
          if (_scanningDevices)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('正在扫描局网设备...'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // 设备列表
          Expanded(
            child: _discoveredDevices.isEmpty
                ? (_scanningDevices
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.devices_other, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('暂未发现设备', style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 4),
                            Text('确保 ESP32 已开机并连接同一 WiFi', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ))
                : ListView.builder(
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _discoveredDevices[index];
                      final isSelected = _selectedDevice?.ip == device.ip;
                      final typeEnum = DeviceType.fromString(device.type);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? theme.colorScheme.primaryContainer : null,
                        child: ListTile(
                          leading: Text(typeEnum.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${device.ip} • ${typeEnum.label}'),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                              : const Icon(Icons.chevron_right),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                              _deviceNameController.text = device.name;
                              _topicController.text = device.topicPrefix;
                              _selectedType = typeEnum;
                            });
                            _goToStep(2);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // 手动添加按钮
          OutlinedButton.icon(
            onPressed: _showManualAddDialog,
            icon: const Icon(Icons.edit),
            label: const Text('手动输入 IP 添加'),
          ),
          const SizedBox(height: 8),

          // 下一步按钮
          if (_selectedDevice != null)
            FilledButton(
              onPressed: () => _goToStep(2),
              child: const Text('下一步'),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 步骤3：确认信息
  // ══════════════════════════════════════════

  Widget _buildConfirmStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 步骤标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('3', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text('确认信息', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // 设备信息卡片
          if (_selectedDevice != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_selectedType.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(_selectedDevice!.ip, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 设备名称
          TextField(
            controller: _deviceNameController,
            decoration: const InputDecoration(
              labelText: '设备名称',
              hintText: '例如：客厅主灯',
              prefixIcon: Icon(Icons.devices),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 选择房间
          Text('所在房间', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rooms.map((room) {
              final selected = _selectedRoom == room;
              return ChoiceChip(
                label: Text(room),
                selected: selected,
                onSelected: (_) => setState(() => _selectedRoom = room),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 选择设备类型
          Text('设备类型', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // MQTT 主题（自动生成，可修改）
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'MQTT 主题前缀',
              hintText: '自动生成，也可手动修改',
              prefixIcon: Icon(Icons.topic),
              border: OutlineInputBorder(),
              helperText: '格式: home/房间/设备名',
            ),
          ),
          const SizedBox(height: 24),

          // 添加按钮
          FilledButton.icon(
            onPressed: _submitDevice,
            icon: const Icon(Icons.check),
            label: const Text('确认添加'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // 操作方法
  // ══════════════════════════════════════════

  /// 扫描 WiFi
  Future<void> _scanWifi() async {
    setState(() => _scanningWifi = true);
    try {
      final list = await _wifiService.scanNetworks();
      setState(() => _wifiList = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    } finally {
      setState(() => _scanningWifi = false);
    }
  }

  /// 连接 WiFi（提示用户手动连接）
  Future<void> _connectWifi() async {
    if (_selectedWifi == null) return;

    setState(() => _connectingWifi = true);

    // Android 限制：App 无法直接连接 WiFi，需要用户手动操作
    // 显示引导对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('连接 WiFi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text('请手动连接 WiFi:', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                _selectedWifi!.ssid,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('1. 打开手机设置\n2. 连接上方 WiFi\n3. 输入密码\n4. 返回此 App'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _checkCurrentWifi();
              },
              child: const Text('已连接，继续'),
            ),
          ],
        ),
      );
    }

    setState(() => _connectingWifi = false);
  }

  /// 开始扫描设备
  Future<void> _startDeviceScan() async {
    setState(() {
      _scanningDevices = true;
      _discoveredDevices.clear();
    });

    try {
      final devices = await _discoveryService.scanDevices();
      setState(() => _discoveredDevices = devices);
    } catch (e) {
      debugPrint('[AddDevice] 扫描设备失败: $e');
    } finally {
      setState(() => _scanningDevices = false);
    }
  }

  /// 手动输入 IP 添加
  void _showManualAddDialog() {
    final ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动添加设备'),
        content: TextField(
          controller: ipController,
          decoration: const InputDecoration(
            labelText: 'ESP32 IP 地址',
            hintText: '例如: 192.168.1.105',
            prefixIcon: Icon(Icons.language),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                final device = DiscoveredDevice(
                  name: 'ESP32设备',
                  type: 'other',
                  ip: ip,
                  topicPrefix: 'home/device_${ip.replaceAll('.', '_')}',
                );
                setState(() {
                  _discoveredDevices.add(device);
                  _selectedDevice = device;
                  _deviceNameController.text = device.name;
                  _topicController.text = device.topicPrefix;
                });
                Navigator.pop(ctx);
                _goToStep(2);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  /// 提交设备
  void _submitDevice() {
    if (_deviceNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入设备名称')),
      );
      return;
    }

    // 自动生成主题前缀（如果用户没改）
    String topicPrefix = _topicController.text.trim();
    if (topicPrefix.isEmpty || topicPrefix == _selectedDevice?.topicPrefix) {
      final roomPinyin = _roomToPinyin(_selectedRoom);
      final namePinyin = _nameToPinyin(_deviceNameController.text.trim());
      topicPrefix = 'home/$roomPinyin/$namePinyin';
    }

    final device = Device(
      name: _deviceNameController.text.trim(),
      topicPrefix: topicPrefix,
      deviceType: _selectedType,
    );

    context.read<DeviceProvider>().addDevice(device);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加: ${device.name}')),
    );

    Navigator.pop(context);
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// 信号强度图标
  IconData _getSignalIcon(int level) {
    if (level > -50) return Icons.wifi;
    if (level > -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  /// 简单的中文转拼音（用英文替代）
  String _roomToPinyin(String room) {
    const map = {
      '客厅': 'livingroom',
      '卧室': 'bedroom',
      '厨房': 'kitchen',
      '卫生间': 'bathroom',
      '阳台': 'balcony',
      '书房': 'study',
      '走廊': 'hallway',
      '其他': 'other',
    };
    return map[room] ?? 'room';
  }

  String _nameToPinyin(String name) {
    // 简单处理：用设备类型代替
    return name.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
  }
}
