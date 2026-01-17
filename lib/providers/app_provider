import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import '../models/room.dart';
import '../models/log_entry.dart';
import '../models/wifi_network.dart';
import '../utils/notification_helper.dart';

enum AppMode { remote, localAuto }

class AppProvider extends ChangeNotifier {
  static const String authKey = 'hodo8212';
  static const int emergencyStopLevel = 98;
  static const String parentESPUrl = 'http://192.168.1.100';

  bool _isDarkMode = true;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isSimulationEnabled = false;
  bool _encryptionEnabled = false;
  bool _notificationsEnabled = true;
  double _syncProgress = 0;
  AppMode _appMode = AppMode.remote;
  String _appName = 'Home Circuit';
  int _pumpMinThreshold = 20;
  int _pumpMaxThreshold = 80;

  List<Device> _devices = [];
  List<Room> _rooms = [];
  List<LogEntry> _logs = [];
  List<WifiNetwork> _wifiNetworks = [];

  Timer? _simulationTimer;
  final _uuid = const Uuid();

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  bool get isSimulationEnabled => _isSimulationEnabled;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get syncProgress => _syncProgress;
  AppMode get appMode => _appMode;
  String get appName => _appName;
  int get pumpMinThreshold => _pumpMinThreshold;
  int get pumpMaxThreshold => _pumpMaxThreshold;

  List<Device> get devices => List.unmodifiable(_devices);
  List<Room> get rooms => List.unmodifiable(_rooms);
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<WifiNetwork> get wifiNetworks => List.unmodifiable(_wifiNetworks);
  List<Device> get onlineDevices => _devices.where((d) => d.isOnline).toList();
  List<Device> get activeDevices => _devices.where((d) => d.isOn).toList();
  List<Device> get lightDevices => _devices.where((d) => d.type == DeviceType.light).toList();

  Future<void> initialize() async {
    await _loadFromStorage();
    _isInitialized = true;
    notifyListeners();
    if (_isSimulationEnabled) _startSimulation();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToStorage();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveToStorage();
    notifyListeners();
  }

  void setAppName(String name) {
    _appName = name;
    _saveToStorage();
    notifyListeners();
  }

  bool switchToLocalAuto(String key) {
    if (key != authKey) return false;
    _appMode = AppMode.localAuto;
    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'Switched to Local Auto mode');
    _saveToStorage();
    notifyListeners();
    return true;
  }

  void switchToRemote() {
    _appMode = AppMode.remote;
    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'Switched to Remote mode');
    _saveToStorage();
    notifyListeners();
  }

  void setPumpThresholds(int min, int max) {
    _pumpMinThreshold = min;
    _pumpMaxThreshold = max;
    
    http.post(
      Uri.parse('$parentESPUrl/thresholds'),
      body: {
        'min': min.toString(),
        'max': max.toString(),
      },
    ).timeout(const Duration(seconds: 2));
    
    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.threshold, action: 'Pump thresholds updated', details: 'Min: $min%, Max: $max%');
    _saveToStorage();
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  void setDeviceNotifications(String deviceId, bool enabled) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(notificationsEnabled: enabled);
      _saveToStorage();
      notifyListeners();
    }
  }

  void setEncryptionEnabled(bool enabled) {
    _encryptionEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  void setSimulationEnabled(bool enabled) {
    _isSimulationEnabled = enabled;
    if (enabled) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
    _saveToStorage();
    notifyListeners();
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) => _runSimulation());
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _runSimulation() {
    final random = math.Random();
    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      _devices[i] = device.copyWith(isOnline: random.nextDouble() > 0.1, lastSeen: DateTime.now());

      if (device.type == DeviceType.waterPump) {
        int newLevel = device.isOn ? (device.waterLevel + random.nextInt(5) + 1).clamp(0, 100) : (device.waterLevel - random.nextInt(3)).clamp(0, 100);
        bool shouldBeOn = device.isOn;

        if (_appMode == AppMode.remote) {
          if (newLevel <= _pumpMinThreshold && !device.isOn) {
            shouldBeOn = true;
            _addLog(deviceId: device.id, deviceName: device.name, type: LogType.deviceOn, action: 'Auto ON - Below minimum threshold', details: 'Water level: $newLevel%');
          } else if (newLevel >= _pumpMaxThreshold && device.isOn) {
            shouldBeOn = false;
            _addLog(deviceId: device.id, deviceName: device.name, type: LogType.deviceOff, action: 'Auto OFF - Above maximum threshold', details: 'Water level: $newLevel%');
          }
        }

        if (newLevel >= emergencyStopLevel && device.isOn) {
          shouldBeOn = false;
          _addLog(deviceId: device.id, deviceName: device.name, type: LogType.warning, action: 'EMERGENCY STOP', details: 'Water level reached $newLevel%');
        }

        _devices[i] = _devices[i].copyWith(waterLevel: newLevel, isOn: shouldBeOn);
      }

      if (device.type == DeviceType.gasSensor) {
        _devices[i] = device.copyWith(lpgValue: (random.nextDouble() * 100).clamp(0, 100), coValue: (random.nextDouble() * 50).clamp(0, 50));
      }

      if (device.hasBattery && device.batteryLevel != null) {
        _devices[i] = _devices[i].copyWith(batteryLevel: (device.batteryLevel! - random.nextInt(2)).clamp(0, 100));
      }
    }
    _saveToStorage();
    notifyListeners();
  }

  Future<void> syncDevices() async {
    _isSyncing = true;
    _syncProgress = 0;
    notifyListeners();

    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.sync, action: 'Device sync started');

    try {
      final response = await http.get(Uri.parse('$parentESPUrl/status')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['tanks'] != null) {
          final tanks = data['tanks'] as List;
          
          for (var tankData in tanks) {
            final tankName = tankData['name'];
            final level = tankData['level'];
            final battery = tankData['battery'];
            final isOnline = tankData['online'] ?? false;
            final isPumpOn = tankData['pump'] ?? false;
            
            final deviceIndex = _devices.indexWhere((d) => d.name == tankName);
            
            if (deviceIndex != -1) {
              final device = _devices[deviceIndex];
              final oldIsOn = device.isOn;
              
              if (isPumpOn != oldIsOn && device.shouldHaveStatusPin) {
                _addLog(deviceId: device.id, deviceName: device.name, type: LogType.info, action: 'Manual override detected', details: 'Device ${isPumpOn ? 'turned ON' : 'turned OFF'} manually');
                
                if (_notificationsEnabled && device.notificationsEnabled) {
                  NotificationHelper.showDeviceStatusChange(deviceName: device.name, isOn: isPumpOn, reason: 'Manual override detected');
                }
              }
              
              _devices[deviceIndex] = device.copyWith(
                isOnline: isOnline,
                isOn: isPumpOn,
                waterLevel: level ?? device.waterLevel,
                batteryLevel: battery ?? device.batteryLevel,
                lastSeen: DateTime.now(),
              );
            }
          }
        }
        
        _addLog(deviceId: 'system', deviceName: 'System', type: LogType.sync, action: 'Sync completed', details: 'Successfully synced with parent ESP');
      }
    } catch (e) {
      _addLog(deviceId: 'system', deviceName: 'System', type: LogType.error, action: 'Sync failed', details: e.toString());
    }

    _isSyncing = false;
    _saveToStorage();
    notifyListeners();
  }

  Future<bool> masterSwitch(String key, bool turnOn) async {
    if (key != authKey) return false;
    final lights = lightDevices;
    int successCount = 0;
    int failCount = 0;

    for (final light in lights) {
      await Future.delayed(const Duration(milliseconds: 200));
      final success = math.Random().nextDouble() > 0.1;
      if (success) {
        final index = _devices.indexWhere((d) => d.id == light.id);
        if (index != -1) {
          _devices[index] = _devices[index].copyWith(isOn: turnOn);
          successCount++;
        }
        _addLog(deviceId: light.id, deviceName: light.name, type: turnOn ? LogType.deviceOn : LogType.deviceOff, action: 'Master Switch: ${turnOn ? 'ON' : 'OFF'}');
      } else {
        failCount++;
        _addLog(deviceId: light.id, deviceName: light.name, type: LogType.error, action: 'Master Switch command failed');
      }
    }

    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'Master Switch completed', details: 'Success: $successCount, Failed: $failCount');
    _saveToStorage();
    notifyListeners();
    return failCount == 0;
  }

  void addDevice(Device device) {
    _devices.add(device);
    _addLog(deviceId: device.id, deviceName: device.name, type: LogType.info, action: 'Device added', details: 'Type: ${device.type.displayName}');
    _saveToStorage();
    notifyListeners();
  }

  void updateDevice(Device device) {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteDevice(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    _devices.removeWhere((d) => d.id == id);
    _addLog(deviceId: id, deviceName: device.name, type: LogType.info, action: 'Device deleted');
    _saveToStorage();
    notifyListeners();
  }

  Future<bool> toggleDevice(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return false;
    if (_appMode == AppMode.localAuto) return false;

    final device = _devices[index];
    final newState = !device.isOn;

    try {
      final Map<String, String> body = {
        'device': (index + 1).toString(),
        'action': newState ? 'on' : 'off',
      };
      
      if (newState) {
        if (device.type == DeviceType.light) {
          body['brightness'] = device.brightness.toString();
        } else if (device.type == DeviceType.fan) {
          body['speed'] = device.fanSpeed.toString();
        }
      }

      final response = await http.post(Uri.parse('$parentESPUrl/control'), body: body).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _devices[index] = device.copyWith(isOn: newState);
        _addLog(deviceId: device.id, deviceName: device.name, type: newState ? LogType.deviceOn : LogType.deviceOff, action: newState ? 'Turned ON' : 'Turned OFF');
        _saveToStorage();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _addLog(deviceId: device.id, deviceName: device.name, type: LogType.error, action: 'Command failed', details: e.toString());
    }
    
    notifyListeners();
    return false;
  }

  void setBrightness(String id, int brightness) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      _devices[index] = device.copyWith(brightness: brightness.clamp(0, 100));
      
      if (device.isOnline && device.isOn) {
        http.post(
          Uri.parse('$parentESPUrl/control'),
          body: {
            'device': (index + 1).toString(),
            'action': 'on',
            'brightness': brightness.toString(),
          },
        ).timeout(const Duration(seconds: 2));
      }
      
      _saveToStorage();
      notifyListeners();
    }
  }

  void setFanSpeed(String id, int speed) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      _devices[index] = device.copyWith(fanSpeed: speed.clamp(1, 5));
      
      if (device.isOnline && device.isOn) {
        http.post(
          Uri.parse('$parentESPUrl/control'),
          body: {
            'device': (index + 1).toString(),
            'action': 'on',
            'speed': speed.toString(),
          },
        ).timeout(const Duration(seconds: 2));
      }
      
      _saveToStorage();
      notifyListeners();
    }
  }

  void addRoom(Room room) {
    _rooms.add(room);
    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'Room added: ${room.name}');
    _saveToStorage();
    notifyListeners();
  }

  void updateRoom(Room room) {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteRoom(String id) {
    final room = _rooms.firstWhere((r) => r.id == id);
    _rooms.removeWhere((r) => r.id == id);
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].roomId == id) {
        _devices[i] = _devices[i].copyWith(roomId: null);
      }
    }
    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'Room deleted: ${room.name}');
    _saveToStorage();
    notifyListeners();
  }

  void moveDevicesToRoom(List<String> deviceIds, String? newRoomId) {
    for (final id in deviceIds) {
      final index = _devices.indexWhere((d) => d.id == id);
      if (index != -1) {
        _devices[index] = _devices[index].copyWith(roomId: newRoomId);
      }
    }
    _saveToStorage();
    notifyListeners();
  }

  List<Device> getDevicesForRoom(String? roomId) {
    return _devices.where((d) => d.roomId == roomId).toList();
  }

  void addWifiNetwork(WifiNetwork network) {
    _wifiNetworks.add(network);
    _saveToStorage();
    notifyListeners();
  }

  void updateWifiNetwork(WifiNetwork network) {
    final index = _wifiNetworks.indexWhere((n) => n.id == network.id);
    if (index != -1) {
      _wifiNetworks[index] = network;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteWifiNetwork(String id) {
    _wifiNetworks.removeWhere((n) => n.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void _addLog({required String deviceId, required String deviceName, required LogType type, required String action, String? details}) {
    _logs.insert(0, LogEntry(id: _uuid.v4(), timestamp: DateTime.now(), deviceId: deviceId, deviceName: deviceName, type: type, action: action, details: details));
    if (_logs.length > 1000) {
      _logs = _logs.sublist(0, 1000);
    }
  }

  void clearLogs() {
    _logs.clear();
    _saveToStorage();
    notifyListeners();
  }

  List<LogEntry> getFilteredLogs({DateTime? startDate, DateTime? endDate, String? deviceId, LogType? logType}) {
    return _logs.where((log) {
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate.add(const Duration(days: 1)))) return false;
      if (deviceId != null && log.deviceId != deviceId) return false;
      if (logType != null && log.type != logType) return false;
      return true;
    }).toList();
  }

  String exportLogsToCSV(List<LogEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Device,Type,Action,Details');
    for (final entry in entries) {
      buffer.writeln(entry.toCSV());
    }
    return buffer.toString();
  }

  String generateArduinoCode() {
    final buffer = StringBuffer();
    buffer.writeln('/*');
    buffer.writeln(' * $appName - Arduino/ESP Device Controller');
    buffer.writeln(' * Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln(' * Devices: ${_devices.length}');
    buffer.writeln(' */');
    buffer.writeln();
    buffer.writeln('#include <ESP8266WiFi.h>');
    buffer.writeln('#include <ESP8266WebServer.h>');
    buffer.writeln('#include <ArduinoJson.h>');
    buffer.writeln();
    buffer.writeln('// ========== WIFI CONFIGURATION ==========');
    if (_wifiNetworks.isNotEmpty) {
      buffer.writeln('const char* WIFI_SSID = "${_wifiNetworks.first.ssid}";');
      buffer.writeln('const char* WIFI_PASSWORD = "${_encryptionEnabled ? '********' : _wifiNetworks.first.password}";');
    } else {
      buffer.writeln('const char* WIFI_SSID = "YOUR_WIFI_SSID";');
      buffer.writeln('const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";');
    }
    buffer.writeln();
    buffer.writeln('// ========== RELAY CONFIGURATION ==========');
    buffer.writeln('// Using optocoupler (PC817) with ACTIVE LOW relays');
    buffer.writeln('#define RELAY_ON  HIGH');
    buffer.writeln('#define RELAY_OFF LOW');
    buffer.writeln();
    buffer.writeln('// ========== THRESHOLD CONFIGURATION ==========');
    buffer.writeln('int currentPumpMin = $_pumpMinThreshold;');
    buffer.writeln('int currentPumpMax = $_pumpMaxThreshold;');
    buffer.writeln('const int EMERGENCY_STOP_LEVEL = $emergencyStopLevel;');
    buffer.writeln();
    
    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      buffer.writeln('// Device $i: ${device.name}');
      buffer.writeln('const char* DEV_${i}_NAME = "${device.name}";');
      buffer.writeln('const char* DEV_${i}_IP = "${device.ipAddress}";');
      if (device.gpioPin != null) buffer.writeln('const int DEV_${i}_GPIO = ${device.gpioPin};');
      if (device.statusPin != null) buffer.writeln('const int DEV_${i}_STATUS = ${device.statusPin};');
      buffer.writeln();
    }

    buffer.writeln('ESP8266WebServer server(80);');
    buffer.writeln();
    buffer.writeln('void setup() {');
    buffer.writeln('  Serial.begin(115200);');
    buffer.writeln('  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);');
    buffer.writeln('  while (WiFi.status() != WL_CONNECTED) delay(500);');
    buffer.writeln('  Serial.println(WiFi.localIP());');
    buffer.writeln('  server.on("/status", handleStatus);');
    buffer.writeln('  server.on("/control", handleControl);');
    buffer.writeln('  server.begin();');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void loop() { server.handleClient(); }');
    buffer.writeln();
    buffer.writeln('void handleStatus() { /* Implement */ }');
    buffer.writeln('void handleControl() { /* Implement */ }');

    return buffer.toString();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _appName = prefs.getString('appName') ?? 'Home Circuit';
      _appMode = AppMode.values[prefs.getInt('appMode') ?? 0];
      _pumpMinThreshold = prefs.getInt('pumpMinThreshold') ?? 20;
      _pumpMaxThreshold = prefs.getInt('pumpMaxThreshold') ?? 80;
      _isSimulationEnabled = prefs.getBool('isSimulationEnabled') ?? false;
      _encryptionEnabled = prefs.getBool('encryptionEnabled') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      final devicesJson = prefs.getString('devices');
      if (devicesJson != null) {
        _devices = (jsonDecode(devicesJson) as List).map((d) => Device.fromJson(d)).toList();
      }

      final roomsJson = prefs.getString('rooms');
      if (roomsJson != null) {
        _rooms = (jsonDecode(roomsJson) as List).map((r) => Room.fromJson(r)).toList();
      }

      final logsJson = prefs.getString('logs');
      if (logsJson != null) {
        _logs = (jsonDecode(logsJson) as List).map((l) => LogEntry.fromJson(l)).toList();
      }

      final wifiJson = prefs.getString('wifiNetworks');
      if (wifiJson != null) {
        _wifiNetworks = (jsonDecode(wifiJson) as List).map((w) => WifiNetwork.fromJson(w)).toList();
      }

      if (_devices.isEmpty) _addDemoData();
    } catch (e) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setString('appName', _appName);
      await prefs.setInt('appMode', _appMode.index);
      await prefs.setInt('pumpMinThreshold', _pumpMinThreshold);
      await prefs.setInt('pumpMaxThreshold', _pumpMaxThreshold);
      await prefs.setBool('isSimulationEnabled', _isSimulationEnabled);
      await prefs.setBool('encryptionEnabled', _encryptionEnabled);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setString('devices', jsonEncode(_devices.map((d) => d.toJson()).toList()));
      await prefs.setString('rooms', jsonEncode(_rooms.map((r) => r.toJson()).toList()));
      await prefs.setString('logs', jsonEncode(_logs.map((l) => l.toJson()).toList()));
      await prefs.setString('wifiNetworks', jsonEncode(_wifiNetworks.map((w) => w.toJson()).toList()));
    } catch (e) {}
  }

  void _addDemoData() {
    _rooms = [
      Room(id: _uuid.v4(), name: 'Living Room', type: RoomType.livingRoom),
      Room(id: _uuid.v4(), name: 'Kitchen', type: RoomType.kitchen),
      Room(id: _uuid.v4(), name: 'Bedroom', type: RoomType.bedroom),
      Room(id: _uuid.v4(), name: 'Garage', type: RoomType.garage),
    ];

    _devices = [
      Device(id: _uuid.v4(), name: 'Tank 1', type: DeviceType.waterPump, ipAddress: '192.168.1.101', gpioPin: 13, statusPin: 12, roomId: _rooms[3].id, isOnline: true, waterLevel: 65),
      Device(id: _uuid.v4(), name: 'Tank 2', type: DeviceType.waterPump, ipAddress: '192.168.1.102', gpioPin: 14, statusPin: 11, roomId: _rooms[3].id, isOnline: true, waterLevel: 45),
      Device(id: _uuid.v4(), name: 'Tank 3', type: DeviceType.waterPump, ipAddress: '192.168.1.103', gpioPin: 15, statusPin: 10, roomId: _rooms[3].id, isOnline: false, waterLevel: 30),
    ];

    _addLog(deviceId: 'system', deviceName: 'System', type: LogType.info, action: 'App initialized with demo data');
  }

  String generateUuid() => _uuid.v4();

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
