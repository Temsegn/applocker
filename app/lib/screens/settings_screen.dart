import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/device_admin_service.dart';
import '../services/accessibility_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Security Settings
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
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
