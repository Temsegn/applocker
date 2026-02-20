package com.applock.secure.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppLockAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("AppLock", "Accessibility service connected")
        
        // Configure service info
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 100
        setServiceInfo(info)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString()
                if (packageName != null) {
                    // Check if this app is locked
                    // Communicate with Flutter to show lock overlay
                    checkAndLockApp(packageName)
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d("AppLock", "Accessibility service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AppLock", "Accessibility service destroyed")
    }

    private fun checkAndLockApp(packageName: String) {
        // This will communicate with Flutter app to check if app is locked
        // and show overlay if needed
        Log.d("AppLock", "Checking app: $packageName")
        
        // Prevent bypass by immediately bringing app to back if it's locked
        // Critical apps that should always be locked
        val criticalApps = listOf(
            "com.android.settings",
            "com.android.packageinstaller",
            "com.google.android.packageinstaller"
        )
        
        if (criticalApps.contains(packageName)) {
            // Force lock critical apps immediately
            performGlobalAction(GLOBAL_ACTION_BACK)
        }
        
        // Send message to Flutter
        val intent = Intent("com.applock.secure.CHECK_APP_LOCK")
        intent.putExtra("packageName", packageName)
        sendBroadcast(intent)
    }
}
