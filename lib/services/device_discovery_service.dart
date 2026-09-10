import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 设备发现服务
/// 通过 UDP 广播发现局域网内的 ESP32 设备
class DeviceDiscoveryService {
  static const int discoveryPort = 4210;
  static const Duration scanTimeout = Duration(seconds: 5);
  static const String discoverCmd = 'smart_home_discover';

  /// 扫描局域网设备
  /// 向 255.255.255.255:4210 发送广播，等待 ESP32 回复
  Future<List<DiscoveredDevice>> scanDevices() async {
    final devices = <DiscoveredDevice>[];
    final completer = Completer<List<DiscoveredDevice>>();

    try {
      // 创建 UDP socket
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;

      // 监听回复
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final device = _parseDeviceResponse(
                message,
                datagram.address.address,
              );
              if (device != null && !devices.any((d) => d.ip == device.ip)) {
                devices.add(device);
                debugPrint('[Discovery] 发现设备: ${device.name} @ ${device.ip}');
              }
            } catch (e) {
              debugPrint('[Discovery] 解析回复失败: $e');
            }
          }
        }
      });

      // 发送广播
      final broadcastAddr = InternetAddress('255.255.255.255');
      final message = utf8.encode(discoverCmd);
      socket.send(message, broadcastAddr, discoveryPort);
      debugPrint('[Discovery] 已发送广播探测');

      // 也扫描网关IP段（更可靠）
      await _scanSubnet(socket);

      // 等待超时
      await Future.delayed(scanTimeout);
      socket.close();

      debugPrint('[Discovery] 扫描完成，发现 ${devices.length} 个设备');
      return devices;
    } catch (e) {
      debugPrint('[Discovery] 扫描异常: $e');
      return devices;
    }
  }

  /// 扫描子网内的所有IP（补充广播方式）
  Future<void> _scanSubnet(RawDatagramSocket socket) async {
    try {
      final gateway = await _getGatewayIp();
      if (gateway.isEmpty) return;

      final parts = gateway.split('.');
      if (parts.length != 4) return;

      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
      final broadcastAddr = InternetAddress('255.255.255.255');
      final message = utf8.encode(discoverCmd);

      // 扫描常见IP段（1-254），分批发包
      for (int i = 1; i <= 254; i += 10) {
        for (int j = i; j < i + 10 && j <= 254; j++) {
          final ip = '$subnet.$j';
          try {
            socket.send(message, InternetAddress(ip), discoveryPort);
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint('[Discovery] 子网扫描异常: $e');
    }
  }

  /// 获取网关 IP
  Future<String> _getGatewayIp() async {
    try {
      for (final interface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in interface.addresses) {
          // 简单取第一个非回环地址的网关
          final parts = addr.address.split('.');
          if (parts.length == 4 && parts[0] != '127') {
            return '${parts[0]}.${parts[1]}.${parts[2]}.1';
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// 解析设备回复消息
  DiscoveredDevice? _parseDeviceResponse(String message, String ip) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      return DiscoveredDevice(
        name: json['name'] ?? 'ESP32设备',
        type: json['type'] ?? 'other',
        ip: ip,
        topicPrefix: json['topic'] ?? 'home/$ip',
        firmware: json['firmware'] ?? '',
        mac: json['mac'] ?? '',
      );
    } catch (_) {
      // 非 JSON 格式，可能是简单文本回复
      if (message.contains('esp32') || message.contains('smart_home')) {
        return DiscoveredDevice(
          name: 'ESP32设备',
          type: 'other',
          ip: ip,
          topicPrefix: 'home/device_$ip',
        );
      }
      return null;
    }
  }
}

/// 发现的设备信息
class DiscoveredDevice {
  final String name;
  final String type; // light, switch, sensor, fan, thermostat, other
  final String ip;
  final String topicPrefix;
  final String firmware;
  final String mac;

  DiscoveredDevice({
    required this.name,
    required this.type,
    required this.ip,
    required this.topicPrefix,
    this.firmware = '',
    this.mac = '',
  });

  @override
  String toString() => '$name ($ip) [$type]';
}
