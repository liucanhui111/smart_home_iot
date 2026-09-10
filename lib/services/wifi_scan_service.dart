import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// WiFi 扫描服务
/// 扫描附近 WiFi 网络，获取当前连接信息
class WifiScanService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// 扫描附近 WiFi 列表
  Future<List<WiFiAccessPoint>> scanNetworks() async {
    try {
      // 检查是否可以扫描
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        debugPrint('[WiFi] 无法扫描: $canScan');
        return [];
      }

      // 开始扫描
      final result = await WiFiScan.instance.startScan();
      if (!result) {
        debugPrint('[WiFi] 扫描失败');
        return [];
      }

      // 等待扫描完成
      await Future.delayed(const Duration(seconds: 3));

      // 获取结果
      final accessPoints = await WiFiScan.instance.getScannedResults();
      debugPrint('[WiFi] 扫描到 ${accessPoints.length} 个网络');

      // 去重并按信号强度排序
      final seen = <String>{};
      final unique = <WiFiAccessPoint>[];
      for (final ap in accessPoints) {
        if (ap.ssid.isNotEmpty && !seen.contains(ap.ssid)) {
          seen.add(ap.ssid);
          unique.add(ap);
        }
      }
      unique.sort((a, b) => b.level.compareTo(a.level));
      return unique;
    } catch (e) {
      debugPrint('[WiFi] 扫描异常: $e');
      return [];
    }
  }

  /// 获取当前连接的 WiFi 信息
  Future<WifiConnectionInfo> getCurrentConnection() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      final ip = await _networkInfo.getWifiIP();
      final gateway = await _networkInfo.getWifiGatewayIP();
      final subnet = await _networkInfo.getWifiSubmask();

      return WifiConnectionInfo(
        ssid: ssid?.replaceAll('"', '') ?? '',
        ip: ip ?? '',
        gateway: gateway ?? '',
        subnet: subnet ?? '',
      );
    } catch (e) {
      debugPrint('[WiFi] 获取连接信息失败: $e');
      return WifiConnectionInfo.empty();
    }
  }

  /// 检查是否已连接 WiFi
  Future<bool> isConnected() async {
    final info = await getCurrentConnection();
    return info.ip.isNotEmpty;
  }
}

/// WiFi 连接信息
class WifiConnectionInfo {
  final String ssid;
  final String ip;
  final String gateway;
  final String subnet;

  WifiConnectionInfo({
    required this.ssid,
    required this.ip,
    required this.gateway,
    required this.subnet,
  });

  factory WifiConnectionInfo.empty() => WifiConnectionInfo(
        ssid: '',
        ip: '',
        gateway: '',
        subnet: '',
      );

  bool get isConnected => ip.isNotEmpty;
}
