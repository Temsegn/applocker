package com.applock.secure

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * When screen goes off, revoke ALL "allowed without PIN" apps.
 * Next time the user opens any locked app, they will be asked for PIN again.
 */
class ScreenOffReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_SCREEN_OFF) {
            MainActivity.onScreenOff(context)
            Log.d("AppLock", "Screen off – revoked all allowed apps, PIN required again")
        }
    }
}
