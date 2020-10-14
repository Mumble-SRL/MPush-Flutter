package com.mumble.mpush

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONArray
import org.json.JSONObject
import kotlin.random.Random

class MPushFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        val body: String? = message.data["body"]
        var title: String? = message.data["title"]

        Log.d("body", body)
        Log.d("title", title)

        if (title == null) {
            title = Utils.getApplicationName(applicationContext)
        } else {
            if (title.isEmpty()) {
                title = Utils.getApplicationName(applicationContext)
            }
        }

        var image: String? = null
        if (message.data.containsKey("custom")) {
            val custom = message.data["custom"] as String
            Log.d("custom", custom)

            val jCustom = JSONArray(custom)
            for (i in 0 until jCustom.length()) {
                val jObj = jCustom.get(i)
                Log.d("jObj", jObj.toString())

                if (jObj is JSONObject) {
                    if (Utils.isJSONOk(jObj, "media_url")) {
                        var mediaUrl = jObj.getString("media_url")
                        val extension = mediaUrl.substring(mediaUrl.lastIndexOf("."));
                        if (extension.contains("png") ||
                                extension.endsWith("jpg") ||
                                extension.endsWith("jpeg")) {
                            image = mediaUrl
                        }
                    }
                }
            }
        }

        body?.let {
            sendNotification(title!!, body, image)
        }
    }

    fun sendNotification(title: String, body: String, image: String?) {
        if (MpushPlugin.channelId != null) {
            Log.d("body", MpushPlugin.channelId)

            var iconResource: Int? = null
            if (MpushPlugin.icon != null) {
                iconResource = Utils.getDrawableResourceId(applicationContext, MpushPlugin.icon!!)
            }

            val notificationID = Random.nextInt()
            val mNotificationManager = applicationContext.getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            val intent = Utils.getLauncherActivity(applicationContext)
            intent?.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            intent?.putExtra("onMPushNotificationStart", true)

            val contentIntent = PendingIntent.getActivity(applicationContext, notificationID, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            val notificationBuilder = NotificationCompat.Builder(applicationContext, MpushPlugin.channelId!!)

            notificationBuilder.setContentTitle(title)
                    .setAutoCancel(true)
                    .setContentText(body)
                    .setContentIntent(contentIntent)

            if (iconResource != null) {
                notificationBuilder.setSmallIcon(iconResource)
            }

            if (image != null) {
                val bitmap = Utils.getBitmapfromUrl(image)
                if (bitmap != null) {
                    notificationBuilder.setStyle(NotificationCompat.BigPictureStyle()
                            .setSummaryText(body)
                            .bigPicture(bitmap))
                } else {
                    notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
                }
            } else {
                notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
            }

            mNotificationManager.notify(notificationID, notificationBuilder.build())
        }
    }
}