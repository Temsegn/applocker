import 'package:flutter/services.dart';
import 'dart:convert';

class InstalledApp {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}

class InstalledAppsService {
  static const MethodChannel _channel = MethodChannel('applock/installed_apps');

  static Future<List<InstalledApp>> getInstalledApps({
    bool includeSystemApps = false,
    bool includeAppIcons = true,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getInstalledApps',
        {
          'includeSystemApps': includeSystemApps,
        },
      );

      return result.map((app) {
        final Map<String, dynamic> appMap = Map<String, dynamic>.from(app);
        Uint8List? icon;
        
        if (includeAppIcons && appMap['iconBase64'] != null && appMap['iconBase64'].toString().isNotEmpty) {
          try {
            final iconBase64 = appMap['iconBase64'] as String;
            icon = base64Decode(iconBase64);
          } catch (e) {
            // Icon decoding failed, continue without icon
            icon = null;
          }
        }

        return InstalledApp(
          packageName: appMap['packageName'] as String,
          appName: appMap['appName'] as String,
          icon: icon,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get installed apps: $e');
    }
  }
}
