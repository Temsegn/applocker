import 'package:flutter/services.dart';

/// Syncs the list of locked package names to native so the accessibility
/// service can intercept when the user opens a locked app.
class LockSyncService {
  static const MethodChannel _channel = MethodChannel('applock/sync');
  static const EventChannel _eventChannel = EventChannel('applock/lock_events');

  /// Call this whenever the locked apps list changes (add/remove/update).
  static Future<void> syncLockedPackages(List<String> packageNames) async {
    try {
      await _channel.invokeMethod<void>('setLockedPackages', packageNames);
    } on PlatformException catch (e) {
      // Ignore if native not ready
      assert(() {
        print('LockSyncService: setLockedPackages failed: ${e.message}');
        return true;
      }());
    }
  }

  /// Stream of package names when user opened a locked app (native will send these).
  static Stream<String> get lockEvents => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic e) => e?.toString() ?? '');

  /// Whether to show PIN when user opens system Settings screens that affect AppLock (Apps > AppLock, Accessibility > AppLock).
  static Future<bool> getProtectAppLockInSettings() async {
    try {
      final v = await _channel.invokeMethod<bool>('getProtectAppLockInSettings');
      return v ?? true;
    } on PlatformException {
      return true;
    }
  }

  static Future<void> setProtectAppLockInSettings(bool enable) async {
    try {
      await _channel.invokeMethod<void>('setProtectAppLockInSettings', {'enable': enable});
    } on PlatformException catch (_) {}
  }
}
