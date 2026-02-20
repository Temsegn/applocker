import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../widgets/pin_input_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  LoginMode _loginMode = LoginMode.email;
  int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _loadPinLength();
  }

  Future<void> _loadPinLength() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final hasPin = await auth.hasStoredPIN();
    final len = hasPin ? await auth.getPinLength() : 6;
    if (mounted) setState(() => _pinLength = len);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginMode == LoginMode.email) {
      if (!_formKey.currentState!.validate()) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        String errorMessage = 'Login failed. Please try again.';
        // Check if it's an approval issue
        if (authProvider.lastError != null && 
            authProvider.lastError!.contains('approval')) {
          errorMessage = 'Your account is pending approval. Please wait for admin approval.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handlePINLogin(String pin) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithPIN(pin);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = Responsive.horizontalPadding(context);
    final scale = Responsive.scale(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: Responsive.isCompact(context) ? 32 : 48),
                Center(
                  child: Icon(
                    Icons.lock_rounded,
                    size: 88 * scale,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to secure your apps',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.sectionSpacing(context)),
                SegmentedButton<LoginMode>(
                  segments: const [
                    ButtonSegment(value: LoginMode.email, label: Text('Email')),
                    ButtonSegment(value: LoginMode.pin, label: Text('PIN')),
                  ],
                  selected: {_loginMode},
                  onSelectionChanged: (Set<LoginMode> newSelection) {
                    setState(() {
                      _loginMode = newSelection.first;
                    });
                    if (newSelection.first == LoginMode.pin) _loadPinLength();
                  },
                ),
                SizedBox(height: Responsive.sectionSpacing(context)),
                // Email/Password Login
                if (_loginMode == LoginMode.email) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _handleLogin,
                    child: const Text('Sign in'),
                  ),
                ],
                // PIN Login (6 digits)
                if (_loginMode == LoginMode.pin) ...[
                  PinInputWidget(
                    onCompleted: _handlePINLogin,
                    length: _pinLength,
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum LoginMode { email, pin }
