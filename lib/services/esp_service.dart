// lib/services/esp_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum CommunicationProtocol { http, mqtt }

class EspService {
  CommunicationProtocol protocol;
  String? mqttBrokerIp;
  int mqttBrokerPort;
  
  MqttServerClient? _mqttClient;
  final _messageController = StreamController<DeviceMessage>.broadcast();
  
  Stream<DeviceMessage> get messageStream => _messageController.stream;
  bool get isConnected => protocol == CommunicationProtocol.mqtt 
      ? (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected)
      : true;

  EspService({
    this.protocol = CommunicationProtocol.http,
    this.mqttBrokerIp,
    this.mqttBrokerPort = 1883,
  });

  // ==================== MQTT Methods ====================
  
  Future<bool> connectMQTT() async {
    if (protocol != CommunicationProtocol.mqtt || mqttBrokerIp == null) {
      return false;
    }

    try {
      _mqttClient = MqttServerClient(mqttBrokerIp!, '');
      _mqttClient!.port = mqttBrokerPort;
      _mqttClient!.logging(on: false);
      _mqttClient!.keepAlivePeriod = 20;
      _mqttClient!.onDisconnected = _onMqttDisconnected;
      _mqttClient!.onConnected = _onMqttConnected;
      _mqttClient!.onSubscribed = _onMqttSubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      _mqttClient!.connectionMessage = connMessage;

      await _mqttClient!.connect();
      
      if (_mqttClient!.connectionStatus?.state == MqttConnectionState.connected) {
        _setupMqttListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('MQTT connection error: $e');
      _mqttClient?.disconnect();
      return false;
    }
  }

  void _setupMqttListeners() {
    _mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;

      // Parse topic: home/{deviceId}/status
      final parts = topic.split('/');
      if (parts.length >= 3 && parts[0] == 'home' && parts[2] == 'status') {
        final deviceId = parts[1];
        _messageController.add(DeviceMessage(
          deviceId: deviceId,
          topic: topic,
          payload: payload,
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void subscribeMQTT(String deviceId) {
    if (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
      _mqttClient!.subscribe('home/$deviceId/status', MqttQos.atMostOnce);
    }
  }

  void unsubscribeMQTT(String deviceId) {
    if (_mqttClient?.connectionStatus?.state == MqttConnectionState.connected) {
      _mqttClient!.unsubscribe('home/$deviceId/status');
    }
  }

  Future<bool> sendMQTTCommand(String deviceId, String command) async {
    if (_mqttClient?.connectionStatus?.state != MqttConnectionState.connected) {
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      
      _mqttClient!.publishMessage(
        'home/$deviceId/set',
        MqttQos.atMostOnce,
        builder.payload!,
      );
      
      return true;
    } catch (e) {
      print('MQTT publish error: $e');
      return false;
    }
  }

  void disconnectMQTT() {
    _mqttClient?.disconnect();
    _mqttClient = null;
  }

  void _onMqttConnected() {
    print('MQTT connected');
  }

  void _onMqttDisconnected() {
    print('MQTT disconnected');
  }

  void _onMqttSubscribed(String topic) {
    print('Subscribed to: $topic');
  }

  // ==================== HTTP Methods ====================

  Future<DeviceStatusResponse?> getHTTPStatus(String ipAddress) async {
    if (protocol != CommunicationProtocol.http) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DeviceStatusResponse(
          isOn: data['state'] == 'ON',
          isOnline: true,
          brightness: data['brightness'],
          fanSpeed: data['fanSpeed'],
          waterLevel: data['waterLevel'],
          lpgValue: data['lpgValue']?.toDouble(),
          coValue: data['coValue']?.toDouble(),
        );
      }
    } catch (e) {
      print('HTTP status error for $ipAddress: $e');
    }
    
    return null;
  }

  Future<bool> sendHTTPCommand(String ipAddress, String command, {Map<String, dynamic>? data}) async {
    if (protocol != CommunicationProtocol.http) {
      return false;
    }

    try {
      final body = data ?? {'state': command};
      
      final response = await http
          .post(
            Uri.parse('http://$ipAddress/control'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('HTTP command error for $ipAddress: $e');
      return false;
    }
  }

  // ==================== Unified Interface ====================

  Future<bool> sendCommand(String deviceId, String ipAddress, String command, {Map<String, dynamic>? data}) async {
    if (protocol == CommunicationProtocol.mqtt) {
      return await sendMQTTCommand(deviceId, command);
    } else {
      return await sendHTTPCommand(ipAddress, command, data: data);
    }
  }

  Future<DeviceStatusResponse?> getStatus(String deviceId, String ipAddress) async {
    if (protocol == CommunicationProtocol.http) {
      return await getHTTPStatus(ipAddress);
    }
    // For MQTT, status comes via subscriptions
    return null;
  }

  void switchProtocol(CommunicationProtocol newProtocol) {
    if (protocol == newProtocol) return;
    
    if (protocol == CommunicationProtocol.mqtt) {
      disconnectMQTT();
    }
    
    protocol = newProtocol;
  }

  void dispose() {
    disconnectMQTT();
    _messageController.close();
  }
}

class DeviceMessage {
  final String deviceId;
  final String topic;
  final String payload;
  final DateTime timestamp;

  DeviceMessage({
    required this.deviceId,
    required this.topic,
    required this.payload,
    required this.timestamp,
  });
}

class DeviceStatusResponse {
  final bool isOn;
  final bool isOnline;
  final int? brightness;
  final int? fanSpeed;
  final int? waterLevel;
  final double? lpgValue;
  final double? coValue;

  DeviceStatusResponse({
    required this.isOn,
    required this.isOnline,
    this.brightness,
    this.fanSpeed,
    this.waterLevel,
    this.lpgValue,
    this.coValue,
  });
}
