package com.mumble.mpush

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlin.random.Random

class MPushFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        val body: String? = message.data["body"]
        var title: String? = message.data["title"]
        if (title == null) {
            title = Utils.getApplicationName(applicationContext)
        } else {
            if (title.isEmpty()) {
                title = Utils.getApplicationName(applicationContext)
            }
        }

        body?.let {
            sendNotification(title!!, body)
        }
    }

    fun sendNotification(title: String, body: String) {
        if (MpushPlugin.channelId != null) {

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
                    .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                    .setAutoCancel(true)
                    .setContentText(body)
                    .setContentIntent(contentIntent)

            if (iconResource != null) {
                notificationBuilder.setSmallIcon(iconResource)
            }

            mNotificationManager.notify(notificationID, notificationBuilder.build())
        }
    }
}