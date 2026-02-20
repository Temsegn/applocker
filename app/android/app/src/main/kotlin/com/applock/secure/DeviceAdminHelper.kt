package com.applock.secure

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

object DeviceAdminHelper {
    private const val REQUEST_CODE_ENABLE_ADMIN = 1001

    fun requestDeviceAdmin(activity: Activity) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(
            DevicePolicyManager.EXTRA_DEVICE_ADMIN,
            ComponentName(activity, AppLockDeviceAdminReceiver::class.java.name)
        )
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "AppLock needs device administrator privileges to prevent unauthorized uninstallation.")
        activity.startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
    }

    fun isDeviceAdminEnabled(context: Context): Boolean {
        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, AppLockDeviceAdminReceiver::class.java.name)
        return devicePolicyManager.isAdminActive(adminComponent)
    }

    fun disableDeviceAdmin(context: Context, password: String?): Boolean {
        // Verify password before disabling
        // In a real implementation, you would verify the password here
        if (password == null || password.isEmpty()) {
            return false
        }

        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, AppLockDeviceAdminReceiver::class.java.name)
        
        if (devicePolicyManager.isAdminActive(adminComponent)) {
            devicePolicyManager.removeActiveAdmin(adminComponent)
            return true
        }
        return false
    }
}
