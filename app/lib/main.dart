import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'providers/auth_provider.dart';
import 'providers/app_lock_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lock_overlay_screen.dart';
import 'services/lock_sync_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _requestPermissions();
  
  runApp(const AppLockApp());
}

Future<void> _requestPermissions() async {
  await Permission.systemAlertWindow.request();
}

class AppLockApp extends StatefulWidget {
  const AppLockApp({super.key});

  @override
  State<AppLockApp> createState() => _AppLockAppState();
}

class _AppLockAppState extends State<AppLockApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _lockEventsSubscription;

  @override
  void initState() {
    super.initState();
    _lockEventsSubscription = LockSyncService.lockEvents.listen((packageName) {
      if (packageName.isEmpty) return;
      _navigatorKey.currentState?.push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LockOverlayScreen(packageName: packageName),
          fullscreenDialog: true,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
    });
  }

  @override
  void dispose() {
    _lockEventsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppLockProvider()),
      ],
      child: _AppResumeSync(
        child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'AppLock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        scrollBehavior: const _AppScrollBehavior(),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
        ),
      ),
    );
  }
}

/// Syncs locked packages to native when app comes to foreground so accessibility always has latest list.
class _AppResumeSync extends StatefulWidget {
  const _AppResumeSync({required this.child});
  final Widget child;

  @override
  State<_AppResumeSync> createState() => _AppResumeSyncState();
}

class _AppResumeSyncState extends State<_AppResumeSync> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        Provider.of<AppLockProvider>(context, listen: false).forceSyncToNative();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
