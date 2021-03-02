package com.mumble.mpush

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import org.json.JSONObject
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL


class Utils {
    companion object {

        fun getApplicationName(context: Context): String? {
            val applicationInfo: ApplicationInfo = context.applicationInfo
            val stringId = applicationInfo.labelRes
            return if (stringId == 0) applicationInfo.nonLocalizedLabel.toString() else context.getString(stringId)
        }

        fun getLauncherActivity(context: Context): Intent? {
            val packageManager = context.packageManager
            return packageManager.getLaunchIntentForPackage(context.packageName)
        }

        fun getDrawableResourceId(context: Context, name: String): Int {
            return context.resources.getIdentifier(name, "drawable", context.packageName)
        }

        fun getBitmapfromUrl(imageUrl: String): Bitmap? {
            return try {
                val url = URL(imageUrl)
                val connection: HttpURLConnection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connect()
                val input: InputStream = connection.inputStream
                BitmapFactory.decodeStream(input)
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }

        fun isJSONOk(json: JSONObject, key: String): Boolean {
            if (json.has(key)) {
                if (!json.isNull(key)) {
                    return true
                }
            }
            return false
        }

        fun createNotificationChannelPush(context: Context, channelId: String, channelName: String, channelDescription: String) {
            if (Build.VERSION.SDK_INT < 26) {
                return
            }
            val mNotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val importance = NotificationManager.IMPORTANCE_HIGH
            val mChannel = NotificationChannel(channelId, channelName, importance)
            mChannel.description = channelDescription
            mChannel.enableLights(true)
            mChannel.setShowBadge(true)
            mChannel.enableVibration(true)
            mChannel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            mNotificationManager.createNotificationChannel(mChannel)
        }

        fun getSharedPreferences(context: Context?): SharedPreferences? {
            return context?.getSharedPreferences("mpushPreferences", Context.MODE_PRIVATE)
        }

        fun getSharedPreferencesEditor(context: Context?): SharedPreferences.Editor? {
            if (context != null) {
                val prefs = context.getSharedPreferences("mpushPreferences", Context.MODE_PRIVATE)
                return prefs.edit()
            }
            return null
        }
    }
}