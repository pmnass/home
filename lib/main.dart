import 'package:flutter/material.dart';
import 'widgets/device_controls.dart'; // parent/composer screen you created
import 'services/esp_service.dart';

void main() {
  runApp(const HomeCircuitApp());
}

class HomeCircuitApp extends StatelessWidget {
  const HomeCircuitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Circuit',
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF00E5FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00BCD4),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(),
      home: const DeviceListScreen(),
    );
  }
}

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  // Replace or extend this list with your actual static IPs
  static const List<Map<String, String>> devices = [
    {'ip': '192.168.1.100', 'name': 'Gateway (Parent)'},
    {'ip': '192.168.1.101', 'name': 'Device 101'},
    {'ip': '192.168.1.102', 'name': 'Device 102'},
    {'ip': '192.168.1.103', 'name': 'Device 103'},
    // add up to 192.168.1.120 as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Circuit — Devices'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(device['name'] ?? device['ip']!),
            subtitle: Text(device['ip'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceControlsScreen(
                    ip: device['ip']!,
                    name: device['name'] ?? device['ip']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
