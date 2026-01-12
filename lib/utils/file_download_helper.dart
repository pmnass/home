import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileDownloadHelper {
  static Future<bool> downloadLogsCSV(String csvContent, BuildContext context) async {
    try {
      final fileName = 'home_circuit_logs_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      if (Platform.isAndroid) {
        // For Android, use share instead of direct download
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Home Circuit Logs',
          text: 'Exported logs from Home Circuit',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Logs exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Logs saved to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  static Future<bool> downloadArduinoCode(String code, BuildContext context) async {
    try {
      final fileName = 'home_circuit_arduino_${DateTime.now().millisecondsSinceEpoch}.ino';
      
      if (Platform.isAndroid) {
        // For Android, use share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(code);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Home Circuit Arduino Code',
          text: 'Generated Arduino code from Home Circuit',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Arduino code exported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(code);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Code saved to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
