package com.applock.secure

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.applock.secure.service.AppLockForegroundService

class AppLockBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("AppLock", "Boot completed - checking safe mode and restarting service")
            
            // Check if device is in safe mode
            val isSafeMode = SecurityHelper.isSafeMode(context)
            if (isSafeMode) {
                Log.w("AppLock", "Device is in safe mode - will relock after reboot")
                // Store flag to relock all apps when safe mode exits
                val prefs = context.getSharedPreferences("applock_prefs", Context.MODE_PRIVATE)
                prefs.edit().putBoolean("safe_mode_detected", true).apply()
            }
            
            // Restart foreground service
            AppLockForegroundService.startService(context)
            
            // Check for root/tampering
            val securityStatus = SecurityHelper.getSecurityStatus(context)
            if (securityStatus.isCompromised) {
                Log.w("AppLock", "Security compromise detected: Rooted=${securityStatus.isRooted}, " +
                        "SafeMode=${securityStatus.isSafeMode}, " +
                        "DevOptions=${securityStatus.isDeveloperOptionsEnabled}")
                
                // Notify Flutter app about security issues
                val notifyIntent = Intent("com.applock.secure.SECURITY_ALERT")
                notifyIntent.putExtra("isRooted", securityStatus.isRooted)
                notifyIntent.putExtra("isSafeMode", securityStatus.isSafeMode)
                notifyIntent.putExtra("isCompromised", securityStatus.isCompromised)
                context.sendBroadcast(notifyIntent)
            }
        }
    }
}
