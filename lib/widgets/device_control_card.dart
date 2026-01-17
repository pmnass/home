import 'package:flutter/material.dart';
import '../services/esp_service.dart';

class DeviceControlCard extends StatefulWidget {
  final String ip;
  final String name;
  const DeviceControlCard({required this.ip, required this.name, Key? key}) : super(key: key);

  @override
  State<DeviceControlCard> createState() => _DeviceControlCardState();
}

class _DeviceControlCardState extends State<DeviceControlCard> {
  final EspService _service = EspService();
  Map<String, dynamic>? _status;
  String? _error;
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await _service.fetchStatus(widget.ip);
      setState(() { _status = s; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _togglePump(int tankId, bool enable) async {
    final path = 'control/pump';
    final body = {'tankId': tankId, 'pump': enable};
    // optimistic UI update
    setState(() {
      if (_status != null && _status!['tanks'] is List) {
        final list = List.from(_status!['tanks']);
        for (var t in list) {
          if (t['id'] == tankId) t['pump'] = enable;
        }
        _status!['tanks'] = list;
      }
    });
    try {
      await _service.sendCommand(widget.ip, path, body: body);
      await _refresh();
    } catch (e) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Command failed: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tanks = (_status != null && _status!['tanks'] is List) ? List.from(_status!['tanks']) : [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (tanks.isEmpty && !_loading) const Text('No tanks found'),
            for (final t in tanks)
              ListTile(
                title: Text('${t['name']}'),
                subtitle: Text('Level: ${t['level']} Battery: ${t['battery']}'),
                trailing: Switch(
                  value: t['pump'] == true,
                  onChanged: (v) => _togglePump(t['id'] as int, v),
                ),
              ),
            Row(children: [
              ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
            ])
          ],
        ),
      ),
    );
  }
}
