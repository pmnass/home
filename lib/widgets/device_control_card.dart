import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/device.dart';

class DeviceControlCard extends StatelessWidget {
  final Device device;
  const DeviceControlCard({required this.device, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!device.isOnline)
              const Text('Offline', style: TextStyle(color: Colors.red)),
            if (device.type == DeviceType.waterPump)
              ListTile(
                title: Text('Water Pump'),
                subtitle: Text('Level: ${device.waterLevel}%'),
                trailing: Switch(
                  value: device.isOn,
                  onChanged: (v) async {
                    await provider.toggleDevice(device.id);
                  },
                ),
              ),
            if (device.type == DeviceType.light)
              ListTile(
                title: Text('Light'),
                subtitle: Text('Brightness: ${device.brightness}%'),
                trailing: Switch(
                  value: device.isOn,
                  onChanged: (v) async {
                    await provider.toggleDevice(device.id);
                  },
                ),
              ),
            if (device.type == DeviceType.fan)
              ListTile(
                title: Text('Fan'),
                subtitle: Text('Speed: ${device.fanSpeed}'),
                trailing: Switch(
                  value: device.isOn,
                  onChanged: (v) async {
                    await provider.toggleDevice(device.id);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
