package com.mumble.mpush

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import org.json.JSONObject
import kotlin.random.Random


class MPushFirebaseMessagingService : FirebaseMessagingService() {

    val ACTION_CREATED_NOTIFICATION = "mpush_create_notification"
    val ACTION_CLICKED_NOTIFICATION = "mpush_clicked_notification"

    override fun onMessageReceived(message: RemoteMessage) {
        val body: String? = message.data["body"]
        var title: String? = message.data["title"]

        //Log.d("body", body)
        //Log.d("title", title)

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
            //Log.d("custom", custom)
            if (custom != "[]") {
                val jCustom = JSONObject(custom)
                if (Utils.isJSONOk(jCustom, "media_url")) {
                    var mediaUrl = jCustom.getString("media_url")
                    val extension = mediaUrl.substring(mediaUrl.lastIndexOf("."))
                    if (extension.contains("png") ||
                            extension.endsWith("jpg") ||
                            extension.endsWith("jpeg")) {
                        image = mediaUrl
                    }
                }
            }
        }

        sendNotification(message.data, title!!, body, image)
    }

    fun sendNotification(map: Map<String, String>, title: String, body: String?, image: String?) {
        val prefs = Utils.getSharedPreferences(applicationContext)
        val channelId = prefs?.getString("channelId", null)
        val icon = prefs?.getString("icon", null)

        if (channelId != null) {

            val realBody = body ?: "";

            val gson = Gson()

            var iconResource: Int? = null
            if (icon != null) {
                iconResource = Utils.getDrawableResourceId(applicationContext, icon)
            }

            val notificationID = Random.nextInt()
            val mNotificationManager = applicationContext.getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            val intent = Utils.getLauncherActivity(applicationContext)
            intent?.action = ACTION_CLICKED_NOTIFICATION
            intent?.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            intent?.putExtra("map", gson.toJson(map))

            val contentIntent = PendingIntent.getActivity(applicationContext, notificationID, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            val notificationBuilder = NotificationCompat.Builder(applicationContext, channelId)

            notificationBuilder.setContentTitle(title)
                    .setAutoCancel(true)
                    .setContentText(realBody)
                    .setContentIntent(contentIntent)

            if (iconResource != null) {
                notificationBuilder.setSmallIcon(iconResource)
            }

            if (image != null) {
                val bitmap = Utils.getBitmapfromUrl(image)
                if (bitmap != null) {
                    notificationBuilder.setStyle(NotificationCompat.BigPictureStyle()
                            .setSummaryText(realBody)
                            .bigPicture(bitmap))
                } else {
                    notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(realBody))
                }
            } else {
                notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(realBody))
            }

            val createIntent = Intent(ACTION_CREATED_NOTIFICATION)
            createIntent.putExtra("map", gson.toJson(map))
            LocalBroadcastManager.getInstance(applicationContext).sendBroadcast(createIntent)
            mNotificationManager.notify(notificationID, notificationBuilder.build())
        }
    }
}