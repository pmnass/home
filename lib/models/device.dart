import 'package:flutter/material.dart';

enum DeviceType {
  light,
  fan,
  waterPump,
  gasSensor,
  // Add more types as needed
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.light:
        return 'Light';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.waterPump:
        return 'Water Pump';
      case DeviceType.gasSensor:
        return 'Gas Sensor';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.waterPump:
        return Icons.water_drop;
      case DeviceType.gasSensor:
        return Icons.sensors;
    }
  }

  Color get color {
    switch (this) {
      case DeviceType.light:
        return Colors.amber;
      case DeviceType.fan:
        return Colors.blue;
      case DeviceType.waterPump:
        return Colors.cyan;
      case DeviceType.gasSensor:
        return Colors.orange;
    }
  }
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String ipAddress;
  final int? gpioPin;              // OUTPUT pin (controls relay)
  final int? statusGpioPin;        // NEW: INPUT pin (reads physical switch)
  final String? roomId;
  final bool isOnline;
  final bool isOn;
  final DateTime? lastSeen;
  final int? brightness;
  final int? fanSpeed;
  final int waterLevel;
  final double? lpgValue;
  final double? coValue;
  final bool hasBattery;
  final int? batteryLevel;
  final bool notificationsEnabled;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    this.gpioPin,
    this.statusGpioPin,              // NEW
    this.roomId,
    this.isOnline = false,
    this.isOn = false,
    this.lastSeen,
    this.brightness,
    this.fanSpeed,
    this.waterLevel = 0,
    this.lpgValue,
    this.coValue,
    this.hasBattery = false,
    this.batteryLevel,
    this.notificationsEnabled = true,
  });

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? ipAddress,
    int? gpioPin,
    int? statusGpioPin,              // NEW
    String? roomId,
    bool? isOnline,
    bool? isOn,
    DateTime? lastSeen,
    int? brightness,
    int? fanSpeed,
    int? waterLevel,
    double? lpgValue,
    double? coValue,
    bool? hasBattery,
    int? batteryLevel,
    bool? notificationsEnabled,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ipAddress: ipAddress ?? this.ipAddress,
      gpioPin: gpioPin ?? this.gpioPin,
      statusGpioPin: statusGpioPin ?? this.statusGpioPin,  // NEW
      roomId: roomId ?? this.roomId,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      lastSeen: lastSeen ?? this.lastSeen,
      brightness: brightness ?? this.brightness,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      waterLevel: waterLevel ?? this.waterLevel,
      lpgValue: lpgValue ?? this.lpgValue,
      coValue: coValue ?? this.coValue,
      hasBattery: hasBattery ?? this.hasBattery,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'ipAddress': ipAddress,
      'gpioPin': gpioPin,
      'statusGpioPin': statusGpioPin,  // NEW
      'roomId': roomId,
      'isOnline': isOnline,
      'isOn': isOn,
      'lastSeen': lastSeen?.toIso8601String(),
      'brightness': brightness,
      'fanSpeed': fanSpeed,
      'waterLevel': waterLevel,
      'lpgValue': lpgValue,
      'coValue': coValue,
      'hasBattery': hasBattery,
      'batteryLevel': batteryLevel,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values[json['type']],
      ipAddress: json['ipAddress'],
      gpioPin: json['gpioPin'],
      statusGpioPin: json['statusGpioPin'],  // NEW
      roomId: json['roomId'],
      isOnline: json['isOnline'] ?? false,
      isOn: json['isOn'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      brightness: json['brightness'],
      fanSpeed: json['fanSpeed'],
      waterLevel: json['waterLevel'] ?? 0,
      lpgValue: json['lpgValue']?.toDouble(),
      coValue: json['coValue']?.toDouble(),
      hasBattery: json['hasBattery'] ?? false,
      batteryLevel: json['batteryLevel'],
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }
}
