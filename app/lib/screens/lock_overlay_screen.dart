import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../models/locked_app.dart';
import '../utils/responsive.dart';
import '../widgets/pin_input_widget.dart';
import '../services/app_launcher_service.dart';

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
  int _appPinLength = 4;

  @override
  void initState() {
    super.initState();
    _loadAppPinLength();
  }

  Future<void> _loadAppPinLength() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final len = await auth.getPinLength();
    if (mounted) setState(() => _appPinLength = len);
  }

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
      case LockType.pattern:
        // Pattern verification
        break;
    }

    if (isValid) {
      final provider = Provider.of<AppLockProvider>(context, listen: false);
      provider.setCurrentLockedApp(null);
      if (mounted) Navigator.of(context).pop();
      await AppLauncherService.launchApp(app.packageName);
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

    bool valid = false;
    if (app != null && app.pin == pin) {
      valid = true;
    } else if (widget.packageName == 'com.android.settings') {
      // Settings overlay: also accept AppLock login PIN (no separate "default" password)
      valid = await Provider.of<AuthProvider>(context, listen: false).verifyPIN(pin);
    }
    if (valid) {
      provider.setCurrentLockedApp(null);
      final packageName = app?.packageName ?? widget.packageName;
      if (mounted) Navigator.of(context).pop();
      await AppLauncherService.launchApp(packageName);
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
          
          final pad = Responsive.horizontalPadding(context);
          const surfaceDark = Color(0xFF1C1C1E);
          const onSurfaceDark = Color(0xFFE5E5EA);
          const onSurfaceVariant = Color(0xFF8E8E93);

          // Settings (Protect AppLock in system Settings) with no LockedApp entry: use AppLock PIN
          if (app == null && widget.packageName == 'com.android.settings') {
            return Scaffold(
              backgroundColor: surfaceDark,
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(pad * 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 72, color: onSurfaceDark),
                        const SizedBox(height: 20),
                        const Text(
                          'AppLock protection',
                          style: TextStyle(
                            color: onSurfaceDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your AppLock PIN to open this Settings screen',
                          style: TextStyle(color: onSurfaceVariant, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Responsive.sectionSpacing(context)),
                        PinInputWidget(
                          onCompleted: _handlePINVerification,
                          length: _appPinLength,
                          theme: PinInputTheme.dark,
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFF453A), fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Provider.of<AppLockProvider>(context, listen: false).setCurrentLockedApp(null);
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                          child: const Text('Open AppLock', style: TextStyle(color: onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          if (app == null) {
            return Scaffold(
              backgroundColor: surfaceDark,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(pad * 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 72, color: onSurfaceDark),
                        const SizedBox(height: 20),
                        const Text(
                          'This app is locked',
                          style: TextStyle(
                            color: onSurfaceDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextButton(
                          onPressed: () {
                            Provider.of<AppLockProvider>(context, listen: false).setCurrentLockedApp(null);
                            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                          },
                          child: const Text('Open AppLock', style: TextStyle(color: onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: surfaceDark,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pad * 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (app.iconBase64 != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(app.iconBase64!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Icon(Icons.lock_rounded, size: 72, color: onSurfaceDark),
                      const SizedBox(height: 20),
                      Text(
                        app.appName,
                        style: const TextStyle(
                          color: onSurfaceDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.packageName == 'com.android.settings'
                            ? 'Enter PIN or your AppLock PIN to open'
                            : 'Enter PIN or password to open',
                        style: const TextStyle(color: onSurfaceVariant, fontSize: 15),
                      ),
                      SizedBox(height: Responsive.sectionSpacing(context)),
                      if (app.lockType == LockType.password) ...[
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: onSurfaceDark, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: onSurfaceVariant),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: onSurfaceVariant),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2E),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: onSurfaceVariant, width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0A84FF), width: 2),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFFF453A), fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _verifyAndUnlock(app),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Unlock'),
                          ),
                        ),
                      ],
                      if (app.lockType == LockType.pin) ...[
                        PinInputWidget(
                          onCompleted: _handlePINVerification,
                          length: widget.packageName == 'com.android.settings'
                              ? _appPinLength
                              : (app.pin?.length ?? 4),
                          theme: PinInputTheme.dark,
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFF453A), fontSize: 14),
                            ),
                          ),
                      ],
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Provider.of<AppLockProvider>(context, listen: false).setCurrentLockedApp(null);
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        child: const Text('Open AppLock', style: TextStyle(color: onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
