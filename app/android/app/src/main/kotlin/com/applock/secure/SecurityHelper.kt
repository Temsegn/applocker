package com.applock.secure

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.util.Log
import java.io.File

object SecurityHelper {
    
    // Check if device is in Safe Mode
    fun isSafeMode(context: Context): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.SAFE_BOOT_DISALLOWED,
            0
        ) == 0
    }
    
    // Check if device is rooted
    fun isRooted(): Boolean {
        return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
    }
    
    // Method 1: Check for common root binaries
    private fun checkRootMethod1(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        return paths.any { File(it).exists() }
    }
    
    // Method 2: Check for su command availability
    private fun checkRootMethod2(): Boolean {
        return try {
            Runtime.getRuntime().exec("su").let {
                it.waitFor()
                it.exitValue() == 0
            }
        } catch (e: Exception) {
            false
        }
    }
    
    // Method 3: Check for root management apps
    private fun checkRootMethod3(): Boolean {
        val rootApps = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk",
            "com.kingroot.kinguser",
            "com.kingo.root",
            "com.smedialink.oneclickroot",
            "com.zhiqupk.root.global",
            "com.alephzain.framaroot"
        )
        
        // This method requires context, so we'll check via file system instead
        // Root apps often leave traces in /system/app or /data/app
        val rootAppPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/system/app/SuperSU.apk",
            "/system/xbin/daemonsu",
            "/system/etc/init.d/99SuperSUDaemon",
            "/system/bin/.ext/.su",
            "/system/usr/we-need-root/su-backup",
            "/system/xbin/mu",
            "/system/xbin/busybox",
            "/system/bin/su",
            "/dev/com.koushikdutta.superuser.daemon/"
        )
        
        return rootAppPaths.any { File(it).exists() }
    }
    
    // Check if developer options are enabled (potential tampering indicator)
    fun isDeveloperOptionsEnabled(context: Context): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
            0
        ) == 1
    }
    
    // Check if USB debugging is enabled
    fun isUsbDebuggingEnabled(context: Context): Boolean {
        return Settings.Global.getInt(
            context.contentResolver,
            Settings.Global.ADB_ENABLED,
            0
        ) == 1
    }
    
    // Get security status report
    fun getSecurityStatus(context: Context): SecurityStatus {
        return SecurityStatus(
            isRooted = isRooted(),
            isSafeMode = isSafeMode(context),
            isDeveloperOptionsEnabled = isDeveloperOptionsEnabled(context),
            isUsbDebuggingEnabled = isUsbDebuggingEnabled(context)
        )
    }
    
    data class SecurityStatus(
        val isRooted: Boolean,
        val isSafeMode: Boolean,
        val isDeveloperOptionsEnabled: Boolean,
        val isUsbDebuggingEnabled: Boolean
    ) {
        val isCompromised: Boolean
            get() = isRooted || isSafeMode || isDeveloperOptionsEnabled || isUsbDebuggingEnabled
    }
}
