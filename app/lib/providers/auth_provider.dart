import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _email;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get email => _email;
  String? get lastError => _lastError;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      final storedUserId = await _storage.read(key: 'user_id');
      final storedEmail = await _storage.read(key: 'email');

      if (token != null && storedUserId != null) {
        _isAuthenticated = true;
        _userId = storedUserId;
        _email = storedEmail;
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      if (response['success'] == true) {
        await _storage.write(key: 'auth_token', value: response['token']);
        await _storage.write(key: 'user_id', value: response['userId']);
        await _storage.write(key: 'email', value: email);
        
        _isAuthenticated = true;
        _userId = response['userId'];
        _email = email;
        _lastError = null;
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _lastError = response['message'] ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> loginWithPIN(String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedPinHash = await _storage.read(key: 'pin_hash');
      
      if (storedPinHash == null) {
        // First time setup - save PIN and its length
        final pinHash = _hashPin(pin);
        await _storage.write(key: 'pin_hash', value: pinHash);
        await _storage.write(key: 'pin_length', value: pin.length.toString());
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      final pinHash = _hashPin(pin);
      if (storedPinHash == pinHash) {
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('PIN login error: $e');
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    _isLoading = true;
    notifyListeners();

    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access AppLock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Biometric login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, [String? pin]) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await _apiService.register(email, password);
      
      if (response['success'] == true) {
        // Registration successful but user needs approval
        // Don't set authenticated state yet
        _lastError = null;
        
        if (pin != null) {
          final pinHash = _hashPin(pin);
          await _storage.write(key: 'pin_hash', value: pinHash);
          await _storage.write(key: 'pin_length', value: pin.length.toString());
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _lastError = response['message'] ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _isAuthenticated = false;
    _userId = null;
    _email = null;
    notifyListeners();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify PIN without changing auth state. Use for e.g. Settings overlay.
  Future<bool> verifyPIN(String pin) async {
    try {
      final storedPinHash = await _storage.read(key: 'pin_hash');
      if (storedPinHash == null) return false;
      return _hashPin(pin) == storedPinHash;
    } catch (e) {
      debugPrint('verifyPIN error: $e');
      return false;
    }
  }

  static const int _defaultPinLength = 6;

  /// PIN length used for AppLock login and Settings overlay. Stored when PIN is set.
  Future<int> getPinLength() async {
    try {
      final s = await _storage.read(key: 'pin_length');
      if (s == null) return _defaultPinLength;
      final n = int.tryParse(s);
      return n != null && n >= 4 && n <= 12 ? n : _defaultPinLength;
    } catch (e) {
      return _defaultPinLength;
    }
  }

  /// True if user has already set a PIN (so we know length for login UI).
  Future<bool> hasStoredPIN() async {
    try {
      return await _storage.read(key: 'pin_hash') != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyUninstallPassword(String password) async {
    try {
      final storedPassword = await _storage.read(key: 'uninstall_password');
      if (storedPassword == null) {
        // First time - save password
        await _storage.write(key: 'uninstall_password', value: password);
        return true;
      }
      return storedPassword == password;
    } catch (e) {
      debugPrint('Verify uninstall password error: $e');
      return false;
    }
  }
}
