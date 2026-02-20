import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../models/locked_app.dart';
import '../services/installed_apps_service.dart';
import '../widgets/pin_input_widget.dart';

class AppLockSetupScreen extends StatefulWidget {
  final InstalledApp app;
  final bool isLocked;

  const AppLockSetupScreen({
    super.key,
    required this.app,
    required this.isLocked,
  });

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  LockType _selectedLockType = LockType.pin;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _pin;
  bool _isHidden = false;
  bool _isBlocked = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveLock() async {
    final provider = Provider.of<AppLockProvider>(context, listen: false);

    String? password;
    String? pin;
    String? pattern;

    if (_selectedLockType == LockType.password) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      password = _passwordController.text;
    } else if (_selectedLockType == LockType.pin) {
      if (_pin == null || _pin!.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a 4-digit PIN')),
        );
        return;
      }
      pin = _pin;
    }

    final lockedApp = LockedApp(
      packageName: widget.app.packageName,
      appName: widget.app.appName,
      lockType: _selectedLockType,
      password: password,
      pin: pin,
      pattern: pattern,
      isLocked: true,
      isHidden: _isHidden,
      isBlocked: _isBlocked,
    );

    await provider.addAppToLock(lockedApp);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.app.appName} is now locked')),
      );
    }
  }

  Future<void> _removeLock() async {
    final provider = Provider.of<AppLockProvider>(context, listen: false);
    await provider.removeAppFromLock(widget.app.packageName);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.app.appName} is now unlocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app.appName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  widget.app.icon != null
                      ? Image.memory(
                          widget.app.icon!,
                          width: 80,
                          height: 80,
                        )
                      : const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.android, size: 40),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    widget.app.appName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Lock Type Selection
            Text(
              'Lock Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<LockType>(
              segments: const [
                ButtonSegment(value: LockType.pin, label: Text('PIN')),
                ButtonSegment(value: LockType.password, label: Text('Password')),
                ButtonSegment(value: LockType.pattern, label: Text('Pattern')),
                ButtonSegment(value: LockType.biometric, label: Text('Biometric')),
              ],
              selected: {_selectedLockType},
              onSelectionChanged: (Set<LockType> newSelection) {
                setState(() {
                  _selectedLockType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            // PIN Input
            if (_selectedLockType == LockType.pin) ...[
              Text(
                'Enter 4-digit PIN',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              PinInputWidget(
                onCompleted: (pin) {
                  setState(() {
                    _pin = pin;
                  });
                },
                length: 4,
              ),
            ],
            // Password Input
            if (_selectedLockType == LockType.password) ...[
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
            // Pattern (placeholder)
            if (_selectedLockType == LockType.pattern) ...[
              const Center(
                child: Text('Pattern lock UI to be implemented'),
              ),
            ],
            // Biometric
            if (_selectedLockType == LockType.biometric) ...[
              const Center(
                child: Text('Biometric authentication will be used'),
              ),
            ],
            const SizedBox(height: 24),
            // Options
            CheckboxListTile(
              title: const Text('Hide app icon'),
              subtitle: const Text('Hide app from launcher'),
              value: _isHidden,
              onChanged: (value) {
                setState(() {
                  _isHidden = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Block app completely'),
              subtitle: const Text('Prevent app from launching without password'),
              value: _isBlocked,
              onChanged: (value) {
                setState(() {
                  _isBlocked = value ?? false;
                });
              },
            ),
            const SizedBox(height: 32),
            // Action Buttons
            if (widget.isLocked)
              OutlinedButton(
                onPressed: _removeLock,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Remove Lock'),
              )
            else
              ElevatedButton(
                onPressed: _saveLock,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Lock App'),
              ),
          ],
        ),
      ),
    );
  }
}
