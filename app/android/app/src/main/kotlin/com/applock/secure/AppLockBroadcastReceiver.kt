package com.applock.secure

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AppLockBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.applock.secure.CHECK_APP_LOCK") {
            val packageName = intent.getStringExtra("packageName")
            Log.d("AppLock", "Received check app lock broadcast for: $packageName")
            // This will communicate with Flutter to show lock overlay
        }
    }
}
