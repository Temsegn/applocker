import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import '../services/device_admin_service.dart';
import '../services/accessibility_service.dart';
import '../services/lock_sync_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
        children: [
          _buildSectionHeader(context, 'Security'),
          _buildSwitchTile(
            context,
            'Device Administrator',
            'Protect app from uninstallation',
            DeviceAdminService.isDeviceAdminEnabled(),
            (value) async {
              if (value) {
                await DeviceAdminService.requestDeviceAdmin();
              }
            },
          ),
          _buildSwitchTile(
            context,
            'Accessibility Service',
            'Required for app locking',
            AccessibilityService.isAccessibilityServiceEnabled(),
            (value) async {
              if (value) {
                await AccessibilityService.requestAccessibilityPermission();
              }
            },
          ),
          const _ProtectAppLockInSettingsTile(),
          const SizedBox(height: 8),
          _buildProtectAppLockCard(context),
          const Divider(),
          // Account Settings
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Email'),
            subtitle: Consumer<AuthProvider>(
              builder: (context, provider, child) {
                return Text(provider.email ?? 'Not set');
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              // Implement change password
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('Change PIN'),
            onTap: () {
              // Implement change PIN
            },
          ),
          const Divider(),
          // App Settings
          _buildSectionHeader(context, 'App Settings'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Access attempt alerts'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Implement notification toggle
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('Stealth Mode'),
            subtitle: const Text('Hide app icon'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Implement stealth mode
              },
            ),
          ),
          const Divider(),
          // About
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const Divider(),
          // Logout
          ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text('Logout', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w500)),
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildProtectAppLockCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Protect AppLock',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Only two kinds of system Settings ask for PIN when the switch is ON: (1) Settings → Apps → AppLock (app info, force stop). (2) Settings → Accessibility when the screen shows the AppLock service. All other Settings and other Accessibility services do not ask for PIN. You do not need to add Settings to Locked Apps.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    Future<bool> valueFuture,
    Function(bool) onChanged,
  ) {
    return FutureBuilder<bool>(
      future: valueFuture,
      builder: (context, snapshot) {
        return SwitchListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: snapshot.data ?? false,
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Switch to ask for PIN only when opening system Settings that affect AppLock: Apps > AppLock (app info) or Accessibility when AppLock service is shown.
class _ProtectAppLockInSettingsTile extends StatefulWidget {
  const _ProtectAppLockInSettingsTile();

  @override
  State<_ProtectAppLockInSettingsTile> createState() => _ProtectAppLockInSettingsTileState();
}

class _ProtectAppLockInSettingsTileState extends State<_ProtectAppLockInSettingsTile> {
  bool? _value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await LockSyncService.getProtectAppLockInSettings();
    if (mounted) setState(() => _value = v);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.settings_applications_outlined),
      title: const Text('Ask PIN for AppLock in system Settings'),
      subtitle: const Text(
        'When ON: PIN required only when opening Settings that affect AppLock: Apps > AppLock (app info) or Accessibility (when AppLock service is shown). Other Settings and other Accessibility entries are not protected.',
      ),
      value: _value ?? true,
      onChanged: (v) async {
        setState(() => _value = v);
        await LockSyncService.setProtectAppLockInSettings(v);
      },
    );
  }
}
