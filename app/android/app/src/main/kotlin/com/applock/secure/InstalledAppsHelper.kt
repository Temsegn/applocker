package com.applock.secure

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import java.io.ByteArrayOutputStream

data class AppInfo(
    val packageName: String,
    val appName: String,
    val iconBase64: String?
)

object InstalledAppsHelper {
    fun getInstalledApps(context: Context, includeSystemApps: Boolean = false): List<AppInfo> {
        val packageManager = context.packageManager
        val apps = mutableListOf<AppInfo>()
        
        val flags = PackageManager.GET_META_DATA
        
        val installedPackages = packageManager.getInstalledPackages(flags)
        
        for (packageInfo in installedPackages) {
            val appInfo = packageInfo.applicationInfo ?: continue
            
            // Skip system apps if not requested
            if (!includeSystemApps && (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                continue
            }
            
            // Skip apps without launch intent
            val launchIntent = packageManager.getLaunchIntentForPackage(packageInfo.packageName)
            if (launchIntent == null) {
                continue
            }
            
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val icon = getAppIcon(packageManager, appInfo)
            val iconBase64 = icon?.let { bitmapToBase64(it) }
            
            apps.add(AppInfo(
                packageName = packageInfo.packageName,
                appName = appName,
                iconBase64 = iconBase64
            ))
        }
        
        return apps.sortedBy { it.appName }
    }
    
    private fun getAppIcon(packageManager: PackageManager, appInfo: ApplicationInfo): Bitmap? {
        return try {
            val drawable = packageManager.getApplicationIcon(appInfo)
            drawableToBitmap(drawable)
        } catch (e: Exception) {
            null
        }
    }
    
    private fun drawableToBitmap(drawable: Drawable): Bitmap? {
        return if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
            val canvas = android.graphics.Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }
    }
    
    private fun bitmapToBase64(bitmap: Bitmap): String {
        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        val byteArray = outputStream.toByteArray()
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}
