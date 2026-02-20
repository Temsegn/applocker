import 'package:flutter/services.dart';

class AccessibilityService {
  static const MethodChannel _channel = MethodChannel('applock/accessibility');

  // Request accessibility permission
  static Future<bool> requestAccessibilityPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAccessibilityPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Show lock overlay for a package
  static Future<void> showLockOverlay(String packageName) async {
    try {
      await _channel.invokeMethod('showLockOverlay', {'packageName': packageName});
    } catch (e) {
      // Handle error
    }
  }

  // Hide lock overlay
  static Future<void> hideLockOverlay() async {
    try {
      await _channel.invokeMethod('hideLockOverlay');
    } catch (e) {
      // Handle error
    }
  }

  // Enable FLAG_SECURE for an app
  static Future<void> enableSecureFlag(String packageName) async {
    try {
      await _channel.invokeMethod('enableSecureFlag', {'packageName': packageName});
    } catch (e) {
      // Handle error
    }
  }
}
