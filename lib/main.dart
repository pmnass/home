import 'package:flutter/material.dart';
import 'package:provider/provider.dart';   // ✅ Needed for AppProvider
import 'providers/app_provider.dart';      // ✅ Your MQTT logic lives here
import 'screens/device_detail_screen.dart';

void main() {
  runApp(const HomeCircuitApp());
}

class HomeCircuitApp extends StatelessWidget {
  const HomeCircuitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),   // ✅ Auto‑initialize provider
      child: MaterialApp(
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
      ),
    );
  }
}

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Circuit — Devices'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: provider.devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final device = provider.devices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(device.name),
            subtitle: Text(device.ipAddress ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceDetailScreen(
                  device: device,
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
