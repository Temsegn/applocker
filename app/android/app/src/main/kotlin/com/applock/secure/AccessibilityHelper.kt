package com.applock.secure

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.content.pm.PackageManager
import android.app.ActivityManager
import android.content.ComponentName
import com.applock.secure.service.AppLockAccessibilityService

object AccessibilityHelper {
    fun requestAccessibilityPermission(activity: Activity) {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        activity.startActivity(intent)
    }

    fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_ALL_MASK
        )
        
        val serviceName = ComponentName(context, AppLockAccessibilityService::class.java)
        return enabledServices.any { it.resolveInfo.serviceInfo.name == serviceName.className }
    }

    fun showLockOverlay(context: Context, packageName: String?) {
        // This will be handled by the AccessibilityService
        // The service monitors foreground apps and shows overlay when needed
    }

    fun hideLockOverlay(context: Context) {
        // Hide overlay
    }

    fun enableSecureFlag(context: Context, packageName: String?) {
        // Enable FLAG_SECURE for the app
        // This is typically done in the AccessibilityService
    }
}
