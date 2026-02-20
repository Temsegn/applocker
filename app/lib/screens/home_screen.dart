import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../models/locked_app.dart';
import 'app_list_screen.dart';
import 'settings_screen.dart';
import '../services/device_admin_service.dart';
import '../services/accessibility_service.dart';
import '../services/foreground_service.dart';
import '../services/security_service.dart';
import '../models/locked_app.dart';

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
    final provider = Provider.of<AppLockProvider>(context, listen: false);
    
    // Default critical apps to lock: Settings and Package Installer
    const defaultApps = [
      {
        'packageName': 'com.android.settings',
        'appName': 'Settings',
        'lockType': LockType.pin,
      },
      {
        'packageName': 'com.android.packageinstaller',
        'appName': 'Package Installer',
        'lockType': LockType.pin,
      },
    ];

    for (final appData in defaultApps) {
      final existingApp = provider.getLockedApp(appData['packageName'] as String);
      if (existingApp == null) {
        // Check if user wants to lock these by default
        // For now, we'll add them but they can be unlocked
        final app = LockedApp(
          packageName: appData['packageName'] as String,
          appName: appData['appName'] as String,
          lockType: appData['lockType'] as LockType,
          pin: '0000', // Default PIN - user should change this
          isLocked: true,
        );
        await provider.addAppToLock(app);
      }
    }
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
            icon: const Icon(Icons.settings),
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
    return Consumer<AppLockProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.lockedApps.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_open,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No locked apps yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to All Apps to lock your first app',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.lockedApps.length,
          itemBuilder: (context, index) {
            final app = provider.lockedApps[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  child: app.iconPath != null
                      ? Image.asset(app.iconPath!)
                      : const Icon(Icons.android),
                ),
                title: Text(app.appName),
                subtitle: Text('Locked with ${app.lockType.toString().split('.').last}'),
                trailing: Switch(
                  value: app.isLocked,
                  onChanged: (value) {
                    final updatedApp = LockedApp(
                      packageName: app.packageName,
                      appName: app.appName,
                      iconPath: app.iconPath,
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
                onTap: () {
                  // Navigate to app settings
                },
              ),
            );
          },
        );
      },
    );
  }
}
