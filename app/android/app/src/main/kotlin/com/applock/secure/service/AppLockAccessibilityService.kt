package com.applock.secure.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log
import com.applock.secure.MainActivity

class AppLockAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var lastBlockedPackage: String? = null
    private var lastBlockedTime: Long = 0
    private val debounceMs = 800L
    private var previousForegroundPackage: String? = null

    companion object {
        private const val SETTINGS_PACKAGE = "com.android.settings"
        private const val OUR_PACKAGE = "com.applock.secure"
        private val APPLOCK_MARKERS = listOf("applock", "app lock", OUR_PACKAGE)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("AppLock", "Accessibility service connected - monitoring all apps")
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 50
        }
        setServiceInfo(info)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == OUR_PACKAGE) return

        val locked = MainActivity.getLockedPackagesPrefs(this)
            .getStringSet(MainActivity.KEY_LOCKED_PACKAGES, emptySet())
            ?: emptySet()

        // User switched app – if previous was allowed (unlocked), revoke it so PIN is required again
        previousForegroundPackage?.let { prev ->
            if (prev != packageName && MainActivity.isRecentlyUnlocked(this, prev)) {
                MainActivity.addUserLeftPackage(this, prev)
                Log.d("AppLock", "User left $prev – revoked, PIN required on next open")
            }
        }
        previousForegroundPackage = packageName

        // For Settings: only block when "Protect AppLock in system Settings" is ON and screen shows AppLock (Apps > AppLock, Accessibility > AppLock)
        if (packageName == SETTINGS_PACKAGE) {
            if (!MainActivity.getProtectAppLockInSettings(this)) return
            if (MainActivity.isRecentlyUnlocked(this, packageName)) return
            handler.postDelayed({
                if (!settingsWindowShowsAppLock()) return@postDelayed
                triggerLockForPackage(packageName)
            }, 150)
            return
        }

        if (!locked.contains(packageName)) return
        if (MainActivity.isRecentlyUnlocked(this, packageName)) return

        triggerLockForPackage(packageName)
    }

    /** Returns true if the active Settings window content mentions AppLock (e.g. Apps > AppLock app info, or Accessibility screen when AppLock service is shown). Only these screens are protected; other Settings and other Accessibility entries are not. */
    private fun settingsWindowShowsAppLock(): Boolean {
        val root = rootInActiveWindow ?: return false
        return nodeContainsAppLockText(root)
    }

    private fun nodeContainsAppLockText(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString()?.lowercase() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase() ?: ""
        if (APPLOCK_MARKERS.any { text.contains(it) || desc.contains(it) }) return true
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                try {
                    if (nodeContainsAppLockText(child)) return true
                } finally {
                    child.recycle()
                }
            }
        }
        return false
    }

    private fun triggerLockForPackage(packageName: String) {
        val now = System.currentTimeMillis()
        if (packageName == lastBlockedPackage && (now - lastBlockedTime) < debounceMs) return
        lastBlockedPackage = packageName
        lastBlockedTime = now

        Log.d("AppLock", "Locked app opened: $packageName - blocking and showing lock screen")
        performGlobalAction(GLOBAL_ACTION_HOME)
        handler.postDelayed({
            val intent = Intent(this@AppLockAccessibilityService, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION
                )
                putExtra(MainActivity.EXTRA_LOCK_PACKAGE, packageName)
            }
            startActivity(intent)
        }, 80)
    }

    override fun onInterrupt() {
        Log.d("AppLock", "Accessibility service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        Log.d("AppLock", "Accessibility service destroyed")
    }
}
