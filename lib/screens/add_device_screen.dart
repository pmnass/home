import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/device.dart';
import '../models/room.dart';

class AddDeviceScreen extends StatefulWidget {
  final String? preselectedRoomId;

  const AddDeviceScreen({super.key, this.preselectedRoomId});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gpioController = TextEditingController();
  final _statusGpioController = TextEditingController();

  DeviceType _selectedType = DeviceType.light;
  String? _selectedRoomId;
  bool _hasBattery = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gpioController.dispose();
    _statusGpioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CircuitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close,
                color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Add Device',
              style: TextStyle(
                  color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Name
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Name *',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Enter a name' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device Type
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DeviceType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type.displayName),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedType = type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPIO Configuration
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _gpioController,
                          decoration: const InputDecoration(
                            labelText: 'Control GPIO Pin',
                            prefixIcon: Icon(Icons.settings_input_component),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_selectedType == DeviceType.gasSensor ||
                                _selectedType == DeviceType.sensorOnly) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Control pin required';
                            }
                            final pin = int.tryParse(value);
                            if (pin == null || pin < 0 || pin > 16) {
                              return 'Pin must be 0–16';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _statusGpioController,
                          decoration: const InputDecoration(
                            labelText: 'Status GPIO Pin (Optional)',
                            prefixIcon: Icon(Icons.sensors),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return null;
                            final statusPin = int.tryParse(value);
                            if (statusPin == null || statusPin < 0 || statusPin > 16) {
                              return 'Pin must be 0–16';
                            }
                            final controlPin = int.tryParse(_gpioController.text);
                            if (controlPin != null && statusPin == controlPin) {
                              return 'Must differ from control pin';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Room + Battery
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String?>(
                          value: _selectedRoomId,
                          decoration: const InputDecoration(
                            labelText: 'Assign to Room',
                            prefixIcon: Icon(Icons.room_preferences),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('No room')),
                            ...provider.rooms.map((room) => DropdownMenuItem(
                                  value: room.id,
                                  child: Text(room.name),
                                )),
                          ],
                          onChanged: (value) => setState(() => _selectedRoomId = value),
                        ),
                        SwitchListTile(
                          title: const Text('Battery Powered'),
                          value: _hasBattery,
                          onChanged: (val) => setState(() => _hasBattery = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Device'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
  

    final device = // add_device_screen.dart line 202
Device(
  id: const Uuid().v4(),
  name: _nameController.text.trim(),
  type: _selectedType,
  gpioPin: int.tryParse(_gpioController.text),
  statusPin: int.tryParse(_statusGpioController.text),
   roomId: _selectedRoomId,
    hasBattery: _hasBattery,   
);

    provider.addDevice(device);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${device.name} added successfully')),
    );
  }
}
