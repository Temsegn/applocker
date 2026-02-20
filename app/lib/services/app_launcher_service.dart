import 'package:flutter/services.dart';

/// Launches an app by its package name (e.g. after user enters correct PIN).
class AppLauncherService {
  static const MethodChannel _channel = MethodChannel('applock/app_launcher');

  static Future<bool> launchApp(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchApp',
        <String, dynamic>{'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
