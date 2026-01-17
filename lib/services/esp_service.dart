import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EspService {
  final Duration timeout;
  final int maxRetries;

  EspService({this.timeout = const Duration(seconds: 5), this.maxRetries = 2});

  Uri _uri(String ip, String path) => Uri.parse('http://$ip/$path');

  Future<Map<String, dynamic>> fetchStatus(String ip) async {
    final uri = _uri(ip, 'status');
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final resp = await http.get(uri).timeout(timeout);
        if (resp.statusCode == 200) return json.decode(resp.body) as Map<String, dynamic>;
        throw Exception('HTTP ${resp.statusCode}');
      } on TimeoutException {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      } catch (e) {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }

  Future<Map<String, dynamic>> sendCommand(String ip, String path, {Map<String, dynamic>? body}) async {
    final uri = _uri(ip, path);
    int attempt = 0;
    final headers = {'Content-Type': 'application/json'};
    final payload = body == null ? null : json.encode(body);
    while (true) {
      attempt++;
      try {
        final resp = await http.post(uri, headers: headers, body: payload).timeout(timeout);
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (resp.body.isEmpty) return {};
          return json.decode(resp.body) as Map<String, dynamic>;
        }
        throw Exception('HTTP ${resp.statusCode}');
      } on TimeoutException {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      } catch (e) {
        if (attempt > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempt));
      }
    }
  }
}
