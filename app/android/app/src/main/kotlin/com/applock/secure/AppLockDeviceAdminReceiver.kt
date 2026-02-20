package com.applock.secure

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class AppLockDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin enabled
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device admin disabled
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        // This is called when user tries to disable device admin
        // In a real implementation, you would show a password prompt here
        return "Please enter your password to disable AppLock"
    }
}
