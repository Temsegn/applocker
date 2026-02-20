import 'package:flutter/services.dart';

class ForegroundService {
  static const MethodChannel _channel = MethodChannel('applock/foreground_service');

  // Start foreground service
  static Future<bool> startService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startForegroundService');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Stop foreground service
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopForegroundService');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
