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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            // Show online/offline
            Text(
              device.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: device.isOnline ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),

            // Power toggle
            Switch(
              value: device.isOn,
              onChanged: device.isOnline
                  ? (_) async => await provider.toggleDevice(device.id)
                  : null,
            ),

            // Extra controls depending on type
            if (device.type == DeviceType.light)
              Text('Brightness: ${device.brightness ?? 0}%'),
            if (device.type == DeviceType.fan)
              Text('Fan Speed: ${device.fanSpeed ?? 1}'),
            if (device.type == DeviceType.waterPump)
              Text('Water Level: ${device.waterLevel ?? 0}%'),
            if (device.type == DeviceType.gasSensor)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LPG: ${device.lpgValue?.toStringAsFixed(1) ?? '--'} ppm'),
                  Text('CO: ${device.coValue?.toStringAsFixed(1) ?? '--'} ppm'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
