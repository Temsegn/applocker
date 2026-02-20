import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../models/locked_app.dart';
import '../utils/responsive.dart';
import 'app_list_screen.dart';
import 'settings_screen.dart';
import '../services/device_admin_service.dart';
import '../services/accessibility_service.dart';
import '../services/foreground_service.dart';
import '../services/security_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkPermissions();
    await _startProtectionServices();
    await _checkSecurityStatus();
    await _initializeDefaultLocks();
  }

  Future<void> _checkPermissions() async {
    // Check and request device admin
    final isDeviceAdmin = await DeviceAdminService.isDeviceAdminEnabled();
    if (!isDeviceAdmin) {
      await DeviceAdminService.requestDeviceAdmin();
    }

    // Check and request accessibility service
    final isAccessibilityEnabled = await AccessibilityService.isAccessibilityServiceEnabled();
    if (!isAccessibilityEnabled) {
      await AccessibilityService.requestAccessibilityPermission();
    }
  }

  Future<void> _startProtectionServices() async {
    // Start foreground service to prevent casual killing
    await ForegroundService.startService();
  }

  Future<void> _checkSecurityStatus() async {
    final securityStatus = await SecurityService.getSecurityStatus();
    if (securityStatus.isCompromised) {
      // Show security alert
      if (mounted) {
        _showSecurityAlert(securityStatus);
      }
    }
  }

  Future<void> _initializeDefaultLocks() async {
    // Do not auto-lock Settings or Package Installer.
    // User can add them from All Apps and toggle lock ON/OFF as needed.
    // Lock Settings only if you want to prevent force stop and app disable.
  }

  void _showSecurityAlert(SecurityStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Security Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.isRooted)
              const Text('⚠️ Rooted device detected'),
            if (status.isSafeMode)
              const Text('⚠️ Safe mode detected'),
            if (status.isDeveloperOptionsEnabled)
              const Text('⚠️ Developer options enabled'),
            if (status.isUsbDebuggingEnabled)
              const Text('⚠️ USB debugging enabled'),
            const SizedBox(height: 16),
            const Text(
              'Your device security may be compromised. AppLock protection may be bypassed.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppLock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AppListScreen(),
          LockedAppsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apps),
            label: 'All Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock),
            label: 'Locked Apps',
          ),
        ],
      ),
    );
  }
}

class LockedAppsScreen extends StatelessWidget {
  const LockedAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.horizontalPadding(context);
    return Consumer<AppLockProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        if (provider.lockedApps.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(padding * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    size: 72,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No locked apps',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open All Apps and tap an app to lock it',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To protect AppLock from force stop: add Settings in All Apps and turn its lock ON when needed. You can turn it OFF anytime to use Settings freely.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
          cacheExtent: 200,
          itemCount: provider.lockedApps.length,
          itemBuilder: (context, index) {
            final app = provider.lockedApps[index];
            return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: app.iconBase64 != null
                        ? Image.memory(
                            base64Decode(app.iconBase64!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.android, color: theme.colorScheme.primary),
                          ),
                  ),
                  title: Text(
                    app.appName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    app.lockType.toString().split('.').last,
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Switch(
                    value: app.isLocked,
                    onChanged: (value) {
                      final updatedApp = LockedApp(
                        packageName: app.packageName,
                        appName: app.appName,
                        iconPath: app.iconPath,
                        iconBase64: app.iconBase64,
                        lockType: app.lockType,
                        password: app.password,
                        pin: app.pin,
                        pattern: app.pattern,
                        isLocked: value,
                        isHidden: app.isHidden,
                        isBlocked: app.isBlocked,
                        lockScheduleStart: app.lockScheduleStart,
                        lockScheduleEnd: app.lockScheduleEnd,
                      );
                      provider.updateLockedApp(updatedApp);
                    },
                  ),
                ),
            );
          },
        );
      },
    );
  }
}
