import 'package:flutter/services.dart';

class DeviceAdminService {
  static const MethodChannel _channel = MethodChannel('applock/device_admin');

  // Request device admin permission
  static Future<bool> requestDeviceAdmin() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestDeviceAdmin');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if device admin is enabled
  static Future<bool> isDeviceAdminEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceAdminEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Disable device admin (requires password)
  static Future<bool> disableDeviceAdmin(String password) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'disableDeviceAdmin',
        {'password': password},
      );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
