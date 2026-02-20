package com.applock.secure

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.applock.secure.service.AppLockForegroundService

class MainActivity: FlutterActivity() {
    private val CHANNEL_DEVICE_ADMIN = "applock/device_admin"
    private val CHANNEL_ACCESSIBILITY = "applock/accessibility"
    private val CHANNEL_INSTALLED_APPS = "applock/installed_apps"
    private val CHANNEL_FOREGROUND_SERVICE = "applock/foreground_service"
    private val CHANNEL_SECURITY = "applock/security"

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
        
        // Start foreground service on app launch
        AppLockForegroundService.startService(this)
    }
}
