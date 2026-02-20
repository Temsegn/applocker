import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../models/locked_app.dart';
import '../widgets/pin_input_widget.dart';

class LockOverlayScreen extends StatefulWidget {
  final String packageName;

  const LockOverlayScreen({
    super.key,
    required this.packageName,
  });

  @override
  State<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends State<LockOverlayScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndUnlock(LockedApp app) async {
    bool isValid = false;

    switch (app.lockType) {
      case LockType.password:
        isValid = _passwordController.text == app.password;
        break;
      case LockType.pin:
        // PIN verification will be handled by PinInputWidget callback
        break;
      case LockType.biometric:
        // Biometric verification
        break;
      case LockType.pattern:
        // Pattern verification
        break;
    }

    if (isValid) {
      final provider = Provider.of<AppLockProvider>(context, listen: false);
      provider.setCurrentLockedApp(null);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = 'Invalid password. Please try again.';
      });
      _passwordController.clear();
    }
  }

  Future<void> _handlePINVerification(String pin) async {
    final provider = Provider.of<AppLockProvider>(context, listen: false);
    final app = provider.getLockedApp(widget.packageName);

    if (app != null && app.pin == pin) {
      provider.setCurrentLockedApp(null);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from dismissing overlay
      child: Consumer<AppLockProvider>(
        builder: (context, provider, child) {
          final app = provider.getLockedApp(widget.packageName);
          
          if (app == null) {
            return const SizedBox.shrink();
          }

          return Scaffold(
            backgroundColor: Colors.black87,
            body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      app.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This app is locked',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Password Input
                    if (app.lockType == LockType.password) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _verifyAndUnlock(app),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Unlock'),
                      ),
                    ],
                    // PIN Input
                    if (app.lockType == LockType.pin) ...[
                      PinInputWidget(
                        onCompleted: _handlePINVerification,
                        length: 4,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                    // Biometric
                    if (app.lockType == LockType.biometric) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          // Implement biometric unlock
                        },
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Authenticate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
