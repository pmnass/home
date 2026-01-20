import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/mqtt_message.dart';

enum CommunicationProtocol { http, mqtt }

class EspService {
  final CommunicationProtocol protocol;
  final String mqttBrokerIp;
  final int mqttBrokerPort;
  
  MqttServerClient? _mqttClient;
  final StreamController<MqttMessage> _messageController = 
      StreamController<MqttMessage>.broadcast();
  
  Stream<MqttMessage> get messageStream => _messageController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  EspService({
    required this.protocol,
    required this.mqttBrokerIp,
    required this.mqttBrokerPort,
  });

  // ==================== MQTT METHODS ====================
  
  /// Connect to MQTT broker
  Future<bool> connectMQTT() async {
    if (protocol != CommunicationProtocol.mqtt) {
      print('Cannot connect MQTT: Protocol is set to HTTP');
      return false;
    }
    
    try {
      // Create unique client ID
      final clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
      
      _mqttClient = MqttServerClient(mqttBrokerIp, clientId);
      _mqttClient!.port = mqttBrokerPort;
      _mqttClient!.keepAlivePeriod = 60;
      _mqttClient!.autoReconnect = true;
      _mqttClient!.logging(on: false);
      
      // Set up callbacks
      _mqttClient!.onConnected = _onConnected;
      _mqttClient!.onDisconnected = _onDisconnected;
      _mqttClient!.onSubscribed = _onSubscribed;
      _mqttClient!.onAutoReconnect = _onAutoReconnect;
      _mqttClient!.onAutoReconnected = _onAutoReconnected;
      
      // Create connection message
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      _mqttClient!.connectionMessage = connMessage;
      
      print('Connecting to MQTT broker at $mqttBrokerIp:$mqttBrokerPort...');
      
      // Attempt connection
      await _mqttClient!.connect();
      
      if (_mqttClient!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT Connected successfully');
        _isConnected = true;
        
        // Listen to incoming messages
        _mqttClient!.updates!.listen(_onMessage);
        
        return true;
      } else {
        print('MQTT Connection failed - status: ${_mqttClient!.connectionStatus}');
        _isConnected = false;
        _mqttClient!.disconnect();
        return false;
      }
    } catch (e) {
      print('MQTT connection error: $e');
      _isConnected = false;
      _mqttClient?.disconnect();
      return false;
    }
  }

  /// Disconnect from MQTT broker
  void disconnectMQTT() {
    if (_mqttClient != null) {
      print('Disconnecting from MQTT broker...');
      _mqttClient!.disconnect();
      _isConnected = false;
    }
  }

  /// Subscribe to device status topic
  void subscribeMQTT(String deviceId) {
    if (_mqttClient == null || 
        _mqttClient!.connectionStatus!.state != MqttConnectionState.connected) {
      print('Cannot subscribe: MQTT not connected');
      return;
    }
    
    final topic = 'home/$deviceId/status';
    print('Subscribing to topic: $topic');
    _mqttClient!.subscribe(topic, MqttQos.atLeastOnce);
  }

  /// Unsubscribe from device topic
  void unsubscribeMQTT(String deviceId) {
    if (_mqttClient == null || 
        _mqttClient!.connectionStatus!.state != MqttConnectionState.connected) {
      return;
    }
    
    final topic = 'home/$deviceId/status';
    print('Unsubscribing from topic: $topic');
    _mqttClient!.unsubscribe(topic);
  }

  /// Publish command to device via MQTT
  Future<bool> publishMQTT(String deviceId, String command) async {
    if (_mqttClient == null || 
        _mqttClient!.connectionStatus!.state != MqttConnectionState.connected) {
      print('Cannot publish: MQTT not connected');
      return false;
    }
    
    try {
      final topic = 'home/$deviceId/set';
      final builder = MqttClientPayloadBuilder();
      builder.addString(command);
      
      print('Publishing to $topic: $command');
      _mqttClient!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      
      return true;
    } catch (e) {
      print('MQTT publish error: $e');
      return false;
    }
  }

  // ==================== HTTP METHODS ====================
  
  /// Send command via HTTP
  Future<bool> sendHttpCommand(String ipAddress, String command) async {
    if (ipAddress.isEmpty) {
      print('Cannot send HTTP command: IP address is empty');
      return false;
    }
    
    try {
      final url = Uri.parse('http://$ipAddress/control?state=$command');
      print('Sending HTTP command to $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );
      
      print('HTTP response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('HTTP command error: $e');
      return false;
    }
  }

  /// Get device status via HTTP
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId, String ipAddress) async {
    if (ipAddress.isEmpty) {
      print('Cannot get status: IP address is empty');
      return null;
    }
    
    try {
      final url = Uri.parse('http://$ipAddress/status');
      print('Getting status from $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        print('Status response: ${response.body}');
        
        // Try to parse JSON response
        try {
          final data = jsonDecode(response.body);
          return {
            'state': data['state'] ?? 'OFF',
            'online': true,
          };
        } catch (_) {
          // If not JSON, check for simple ON/OFF response
          return {
            'state': response.body.toUpperCase().contains('ON') ? 'ON' : 'OFF',
            'online': true,
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Get status error: $e');
      return null;
    }
  }

  // ==================== UNIFIED METHODS ====================
  
  /// Send command (supports both HTTP and MQTT)
  Future<bool> sendCommand(String deviceId, String ipAddress, String command) async {
    if (protocol == CommunicationProtocol.mqtt) {
      return await publishMQTT(deviceId, command);
    } else {
      return await sendHttpCommand(ipAddress, command);
    }
  }

  // ==================== MQTT CALLBACKS ====================
  
  void _onConnected() {
    print('✓ MQTT Connected');
    _isConnected = true;
  }

  void _onDisconnected() {
    print('✗ MQTT Disconnected');
    _isConnected = false;
  }

  void _onSubscribed(String topic) {
    print('✓ Subscribed to: $topic');
  }

  void _onAutoReconnect() {
    print('⟳ MQTT Auto-reconnecting...');
  }

  void _onAutoReconnected() {
    print('✓ MQTT Auto-reconnected');
    _isConnected = true;
  }

  /// Handle incoming MQTT messages
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      // Extract device ID from topic (format: home/DEVICE_ID/status)
      final topic = message.topic;
      final parts = topic.split('/');
      
      if (parts.length >= 2) {
        final deviceId = parts[1];
        
        print('← Message received from $deviceId: $payload');
        
        // Emit message to stream
        _messageController.add(MqttMessage(
          deviceId: deviceId,
          payload: payload,
        ));
      }
    }
  }

  // ==================== CLEANUP ====================
  
  /// Dispose resources
  void dispose() {
    print('Disposing ESP Service...');
    disconnectMQTT();
    _messageController.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
