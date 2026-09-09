import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../constants.dart';

/// MQTT 服务（单例）
/// 负责连接 Broker、订阅主题、发布消息、管理心跳
class MqttService extends ChangeNotifier {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 消息回调：topic → callback
  final Map<String, Function(String topic, Map<String, dynamic> payload)> _subscriptions = {};

  // 连接状态变化流
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 连接到 MQTT Broker
  Future<bool> connect() async {
    final clientId = '${AppConstants.mqttClientIdPrefix}${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(
      AppConstants.mqttBrokerIp,
      clientId,
      AppConstants.mqttBrokerPort,
    );

    _client!.logging(on: false);
    _client!.keepAlivePeriod = AppConstants.mqttKeepAliveSeconds;
    _client!.autoReconnect = true;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;

    // 连接消息
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    if (AppConstants.mqttUsername.isNotEmpty) {
      connMessage.authenticateAs(AppConstants.mqttUsername, AppConstants.mqttPassword);
    }

    _client!.connectionMessage = connMessage;

    try {
      debugPrint('[MQTT] 正在连接 ${AppConstants.mqttBrokerIp}:${AppConstants.mqttBrokerPort}...');
      await _client!.connect(
        AppConstants.mqttUsername.isNotEmpty ? AppConstants.mqttUsername : null,
        AppConstants.mqttPassword.isNotEmpty ? AppConstants.mqttPassword : null,
      );
    } catch (e) {
      debugPrint('[MQTT] 连接失败: $e');
      _client!.disconnect();
      _setConnectionState(false);
      return false;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _setConnectionState(true);
      _listenToMessages();
      return true;
    } else {
      debugPrint('[MQTT] 连接状态异常: ${_client!.connectionStatus}');
      _setConnectionState(false);
      return false;
    }
  }

  /// 断开连接
  void disconnect() {
    _client?.disconnect();
    _setConnectionState(false);
  }

  /// 订阅主题
  void subscribe(String topic, Function(String topic, Map<String, dynamic> payload) callback) {
    _subscriptions[topic] = callback;
    if (_isConnected && _client != null) {
      _client!.subscribe(topic, MqttQos.atMostOnce);
      debugPrint('[MQTT] 已订阅: $topic');
    }
  }

  /// 取消订阅
  void unsubscribe(String topic) {
    _subscriptions.remove(topic);
    if (_isConnected && _client != null) {
      _client!.unsubscribe(topic);
      debugPrint('[MQTT] 已取消订阅: $topic');
    }
  }

  /// 发布消息
  void publish(String topic, Map<String, dynamic> payload) {
    if (!_isConnected || _client == null) {
      debugPrint('[MQTT] 未连接，无法发布到 $topic');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    debugPrint('[MQTT] 发布: $topic → ${jsonEncode(payload)}');
  }

  /// 监听所有传入消息
  void _listenToMessages() {
    _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final topic = msg.topic;
        final MqttPublishMessage pubMsg = msg.payload as MqttPublishMessage;
        final payloadStr = MqttPublishPayload.bytesToStringAsString(pubMsg.payload.message);

        debugPrint('[MQTT] 收到: $topic → $payloadStr');

        // 尝试解析 JSON
        Map<String, dynamic> payload;
        try {
          payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        } catch (_) {
          payload = {'raw': payloadStr};
        }

        // 匹配精确主题或通配符
        for (final entry in _subscriptions.entries) {
          if (_topicMatches(entry.key, topic)) {
            entry.value(topic, payload);
          }
        }
      }
    });
  }

  /// 简单主题匹配（支持 # 通配符）
  bool _topicMatches(String pattern, String topic) {
    if (pattern == topic) return true;
    if (pattern.endsWith('#')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return topic.startsWith(prefix);
    }
    return false;
  }

  void _onConnected() {
    debugPrint('[MQTT] 已连接');
    _setConnectionState(true);
    // 重新订阅所有主题
    for (final topic in _subscriptions.keys) {
      _client!.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void _onDisconnected() {
    debugPrint('[MQTT] 已断开');
    _setConnectionState(false);
  }

  void _onSubscribed(String topic) {
    debugPrint('[MQTT] 订阅确认: $topic');
  }

  void _setConnectionState(bool connected) {
    _isConnected = connected;
    _connectionStateController.add(connected);
    notifyListeners();
  }
}
