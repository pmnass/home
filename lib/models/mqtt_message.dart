class AppMqttMessage {
  final String deviceId;
  final String payload;
  final DateTime timestamp;

  AppMqttMessage({
    required this.deviceId,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
