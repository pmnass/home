// lib/services/esp_service.dart
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class EspService {
  final String brokerIp;
  final int port;
  late MqttServerClient client;

  EspService({required this.brokerIp, this.port = 1883}) {
    client = MqttServerClient(brokerIp, '');
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
      rethrow;
    }
  }

  /// Subscribe to a device's status topic
  void subscribeStatus(String deviceId, void Function(String message) onMessage) {
    final topic = 'home/$deviceId/status';
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (c[0].topic == topic) {
        onMessage(message);
      }
    });
  }

  /// Send a command to a device (ON/OFF, brightness, etc.)
  void sendCommand(String deviceId, String command) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);

    client.publishMessage(
      'home/$deviceId/set',
      MqttQos.atMostOnce,
      builder.payload!,
    );
  }

  void _onConnected() {
    print('Connected to MQTT broker');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
}
