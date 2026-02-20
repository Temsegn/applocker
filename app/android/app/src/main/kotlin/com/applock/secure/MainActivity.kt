package com.applock.secure

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.applock.secure.service.AppLockForegroundService
import android.content.Intent
import android.util.Log
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager

class MainActivity: FlutterActivity() {

    companion object {
        private const val PREFS_NAME = "applock_prefs"
        const val KEY_LOCKED_PACKAGES = "locked_packages"
        const val KEY_ALLOWED_PACKAGES = "allowed_packages"
        const val KEY_USER_LEFT_PACKAGES = "user_left_packages"
        const val KEY_PROTECT_APPLOCK_IN_SETTINGS = "protect_applock_in_settings"
        const val EXTRA_LOCK_PACKAGE = "lock_package"

        /** When true, show PIN overlay when user opens system Settings screens that affect AppLock (e.g. Apps > AppLock, Accessibility > AppLock). */
        fun getProtectAppLockInSettings(context: Context): Boolean {
            return getLockedPackagesPrefs(context).getBoolean(KEY_PROTECT_APPLOCK_IN_SETTINGS, true)
        }

        /** True if user unlocked this app and has not yet left it + had screen off. */
        fun isRecentlyUnlocked(context: Context, packageName: String): Boolean {
            val allowed = getLockedPackagesPrefs(context)
                .getStringSet(KEY_ALLOWED_PACKAGES, emptySet()) ?: emptySet()
            return allowed.contains(packageName)
        }

        /** Call when user enters correct PIN – app stays allowed until they leave it or screen goes off. */
        fun setRecentlyUnlocked(context: Context, packageName: String) {
            val prefs = getLockedPackagesPrefs(context)
            val allowed = (prefs.getStringSet(KEY_ALLOWED_PACKAGES, emptySet()) ?: emptySet()).toMutableSet()
            val userLeft = (prefs.getStringSet(KEY_USER_LEFT_PACKAGES, emptySet()) ?: emptySet()).toMutableSet()
            allowed.add(packageName)
            userLeft.remove(packageName)
            prefs.edit()
                .putStringSet(KEY_ALLOWED_PACKAGES, allowed)
                .putStringSet(KEY_USER_LEFT_PACKAGES, userLeft)
                .commit()
        }

        /** Call when foreground app changes – user left this app, revoke it immediately so PIN is required again on re-open. */
        fun addUserLeftPackage(context: Context, packageName: String) {
            val prefs = getLockedPackagesPrefs(context)
            val allowed = (prefs.getStringSet(KEY_ALLOWED_PACKAGES, emptySet()) ?: emptySet()).toMutableSet()
            if (!allowed.remove(packageName)) return
            prefs.edit().putStringSet(KEY_ALLOWED_PACKAGES, allowed).commit()
        }

        /** Call when screen goes off – revoke ALL allowed apps so PIN is required again after screen on. */
        fun onScreenOff(context: Context) {
            getLockedPackagesPrefs(context).edit()
                .putStringSet(KEY_ALLOWED_PACKAGES, emptySet<String>())
                .putStringSet(KEY_USER_LEFT_PACKAGES, emptySet<String>())
                .commit()
        }

        fun getLockedPackagesPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }

        @Volatile
        var lockEventSink: EventChannel.EventSink? = null
        @Volatile
        var pendingLockPackage: String? = null
    }

    private val CHANNEL_DEVICE_ADMIN = "applock/device_admin"
    private val CHANNEL_ACCESSIBILITY = "applock/accessibility"
    private val CHANNEL_INSTALLED_APPS = "applock/installed_apps"
    private val CHANNEL_FOREGROUND_SERVICE = "applock/foreground_service"
    private val CHANNEL_SECURITY = "applock/security"
    private val CHANNEL_LOCK_SYNC = "applock/sync"
    private val CHANNEL_LOCK_EVENTS = "applock/lock_events"
    private val CHANNEL_APP_LAUNCHER = "applock/app_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Installed Apps Channel
        val installedAppsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_INSTALLED_APPS)
        installedAppsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
                    try {
                        val apps = InstalledAppsHelper.getInstalledApps(this, includeSystemApps)
                        val appsMap = apps.map { app ->
                            mapOf(
                                "packageName" to app.packageName,
                                "appName" to app.appName,
                                "iconBase64" to (app.iconBase64 ?: "")
                            )
                        }
                        result.success(appsMap)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        val deviceAdminChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_DEVICE_ADMIN)
        deviceAdminChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDeviceAdmin" -> {
                    DeviceAdminHelper.requestDeviceAdmin(this)
                    result.success(true)
                }
                "isDeviceAdminEnabled" -> {
                    result.success(DeviceAdminHelper.isDeviceAdminEnabled(this))
                }
                "disableDeviceAdmin" -> {
                    val password = call.argument<String>("password")
                    result.success(DeviceAdminHelper.disableDeviceAdmin(this, password))
                }
                else -> result.notImplemented()
            }
        }

        val accessibilityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_ACCESSIBILITY)
        accessibilityChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAccessibilityPermission" -> {
                    AccessibilityHelper.requestAccessibilityPermission(this)
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(AccessibilityHelper.isAccessibilityServiceEnabled(this))
                }
                "showLockOverlay" -> {
                    val packageName = call.argument<String>("packageName")
                    AccessibilityHelper.showLockOverlay(this, packageName)
                    result.success(null)
                }
                "hideLockOverlay" -> {
                    AccessibilityHelper.hideLockOverlay(this)
                    result.success(null)
                }
                "enableSecureFlag" -> {
                    val packageName = call.argument<String>("packageName")
                    AccessibilityHelper.enableSecureFlag(this, packageName)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Foreground Service Channel
        val foregroundServiceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_FOREGROUND_SERVICE)
        foregroundServiceChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    AppLockForegroundService.startService(this)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    AppLockForegroundService.stopService(this)
                    result.success(true)
                }
                "isServiceRunning" -> {
                    // Check if service is running (simplified check)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // Security Channel
        val securityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SECURITY)
        securityChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted" -> {
                    result.success(SecurityHelper.isRooted())
                }
                "isSafeMode" -> {
                    result.success(SecurityHelper.isSafeMode(this))
                }
                "getSecurityStatus" -> {
                    val status = SecurityHelper.getSecurityStatus(this)
                    result.success(mapOf(
                        "isRooted" to status.isRooted,
                        "isSafeMode" to status.isSafeMode,
                        "isDeveloperOptionsEnabled" to status.isDeveloperOptionsEnabled,
                        "isUsbDebuggingEnabled" to status.isUsbDebuggingEnabled,
                        "isCompromised" to status.isCompromised
                    ))
                }
                else -> result.notImplemented()
            }
        }

        // Lock sync: Flutter sends list of locked package names so native (accessibility) can intercept
        val syncChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LOCK_SYNC)
        syncChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setLockedPackages" -> {
                    @Suppress("UNCHECKED_CAST")
                    val packages = call.arguments as? List<String> ?: emptyList()
                    getLockedPackagesPrefs(this).edit()
                        .putStringSet(KEY_LOCKED_PACKAGES, packages.toSet())
                        .apply()
                    Log.d("MainActivity", "Synced ${packages.size} locked packages to native")
                    result.success(true)
                }
                "setProtectAppLockInSettings" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    getLockedPackagesPrefs(this).edit()
                        .putBoolean(KEY_PROTECT_APPLOCK_IN_SETTINGS, enable)
                        .apply()
                    Log.d("MainActivity", "Protect AppLock in system Settings: $enable")
                    result.success(true)
                }
                "getProtectAppLockInSettings" -> {
                    result.success(getProtectAppLockInSettings(this))
                }
                else -> result.notImplemented()
            }
        }

        // Launch app by package name (used after successful unlock)
        val appLauncherChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_APP_LAUNCHER)
        appLauncherChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        setRecentlyUnlocked(this, packageName)
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "launchApp failed: ${e.message}")
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Event channel: native sends "show lock screen for this package" to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LOCK_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    lockEventSink = events
                    pendingLockPackage?.let { pkg ->
                        pendingLockPackage = null
                        events?.success(pkg)
                        Log.d("MainActivity", "Sent pending lock_package to Flutter: $pkg")
                    }
                }
                override fun onCancel(arguments: Any?) {
                    lockEventSink = null
                }
            }
        )
        
        // Start foreground service on app launch (with error handling)
        try {
            AppLockForegroundService.startService(this)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to start foreground service: ${e.message}", e)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleLockPackageIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLockPackageIntent(intent)
    }

    private fun handleLockPackageIntent(intent: Intent?) {
        val packageName = intent?.getStringExtra(EXTRA_LOCK_PACKAGE) ?: return
        intent.removeExtra(EXTRA_LOCK_PACKAGE)
        if (lockEventSink != null) {
            lockEventSink?.success(packageName)
            Log.d("MainActivity", "Sent lock_package to Flutter: $packageName")
        } else {
            pendingLockPackage = packageName
            Log.d("MainActivity", "Flutter not ready, pending lock_package: $packageName")
        }
    }
}
