class MqttMessage {
  final String deviceId;
  final String payload;
  final DateTime timestamp;

  MqttMessage({
    required this.deviceId,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
