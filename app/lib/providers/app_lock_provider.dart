import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/locked_app.dart';

class AppLockProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  List<LockedApp> _lockedApps = [];
  bool _isLoading = false;
  String? _currentLockedAppPackage;

  List<LockedApp> get lockedApps => _lockedApps;
  bool get isLoading => _isLoading;
  String? get currentLockedAppPackage => _currentLockedAppPackage;

  AppLockProvider() {
    _loadLockedApps();
  }

  Future<void> _loadLockedApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        // Load from server
        final apps = await _apiService.getLockedApps(userId);
        _lockedApps = apps;
      } else {
        // Load from local storage
        final appsJson = await _storage.read(key: 'locked_apps');
        if (appsJson != null) {
          final List<dynamic> decoded = json.decode(appsJson);
          _lockedApps = decoded.map((json) => LockedApp.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading locked apps: $e');
      // Fallback to local storage
      try {
        final appsJson = await _storage.read(key: 'locked_apps');
        if (appsJson != null) {
          final List<dynamic> decoded = json.decode(appsJson);
          _lockedApps = decoded.map((json) => LockedApp.fromJson(json)).toList();
        }
      } catch (e2) {
        debugPrint('Error loading from local storage: $e2');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAppToLock(LockedApp app) async {
    if (_lockedApps.any((a) => a.packageName == app.packageName)) {
      return;
    }

    _lockedApps.add(app);
    await _saveLockedApps();
    notifyListeners();

    // Sync with server
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        await _apiService.addLockedApp(userId, app);
      }
    } catch (e) {
      debugPrint('Error syncing with server: $e');
    }
  }

  Future<void> removeAppFromLock(String packageName) async {
    _lockedApps.removeWhere((app) => app.packageName == packageName);
    await _saveLockedApps();
    notifyListeners();

    // Sync with server
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId != null) {
        await _apiService.removeLockedApp(userId, packageName);
      }
    } catch (e) {
      debugPrint('Error syncing with server: $e');
    }
  }

  Future<void> updateLockedApp(LockedApp app) async {
    final index = _lockedApps.indexWhere((a) => a.packageName == app.packageName);
    if (index != -1) {
      _lockedApps[index] = app;
      await _saveLockedApps();
      notifyListeners();

      // Sync with server
      try {
        final userId = await _storage.read(key: 'user_id');
        if (userId != null) {
          await _apiService.updateLockedApp(userId, app);
        }
      } catch (e) {
        debugPrint('Error syncing with server: $e');
      }
    }
  }

  Future<void> _saveLockedApps() async {
    try {
      final appsJson = json.encode(_lockedApps.map((app) => app.toJson()).toList());
      await _storage.write(key: 'locked_apps', value: appsJson);
    } catch (e) {
      debugPrint('Error saving locked apps: $e');
    }
  }

  bool isAppLocked(String packageName) {
    return _lockedApps.any((app) => app.packageName == packageName && app.isLocked);
  }

  LockedApp? getLockedApp(String packageName) {
    try {
      return _lockedApps.firstWhere((app) => app.packageName == packageName);
    } catch (e) {
      return null;
    }
  }

  void setCurrentLockedApp(String? packageName) {
    _currentLockedAppPackage = packageName;
    notifyListeners();
  }

  Future<void> checkReinstalledApps(List<String> installedPackages) async {
    // Check if any previously locked apps have been reinstalled
    for (var lockedApp in _lockedApps) {
      if (installedPackages.contains(lockedApp.packageName) && !lockedApp.isLocked) {
        // App was reinstalled, restore lock
        lockedApp.isLocked = true;
        await updateLockedApp(lockedApp);
      }
    }
  }
}
