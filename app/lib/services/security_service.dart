import 'package:flutter/services.dart';

class SecurityStatus {
  final bool isRooted;
  final bool isSafeMode;
  final bool isDeveloperOptionsEnabled;
  final bool isUsbDebuggingEnabled;

  SecurityStatus({
    required this.isRooted,
    required this.isSafeMode,
    required this.isDeveloperOptionsEnabled,
    required this.isUsbDebuggingEnabled,
  });

  bool get isCompromised =>
      isRooted || isSafeMode || isDeveloperOptionsEnabled || isUsbDebuggingEnabled;

  factory SecurityStatus.fromMap(Map<dynamic, dynamic> map) {
    return SecurityStatus(
      isRooted: map['isRooted'] ?? false,
      isSafeMode: map['isSafeMode'] ?? false,
      isDeveloperOptionsEnabled: map['isDeveloperOptionsEnabled'] ?? false,
      isUsbDebuggingEnabled: map['isUsbDebuggingEnabled'] ?? false,
    );
  }
}

class SecurityService {
  static const MethodChannel _channel = MethodChannel('applock/security');

  // Check if device is rooted
  static Future<bool> isRooted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRooted');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if device is in safe mode
  static Future<bool> isSafeMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSafeMode');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get full security status
  static Future<SecurityStatus> getSecurityStatus() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSecurityStatus');
      if (result != null) {
        return SecurityStatus.fromMap(result);
      }
      return SecurityStatus(
        isRooted: false,
        isSafeMode: false,
        isDeveloperOptionsEnabled: false,
        isUsbDebuggingEnabled: false,
      );
    } catch (e) {
      return SecurityStatus(
        isRooted: false,
        isSafeMode: false,
        isDeveloperOptionsEnabled: false,
        isUsbDebuggingEnabled: false,
      );
    }
  }
}
