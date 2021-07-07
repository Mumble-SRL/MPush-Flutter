package com.mumble.mpush

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import org.json.JSONObject
import kotlin.random.Random
import java.io.File

class MPushFirebaseMessagingService : FirebaseMessagingService() {

    val ACTION_CREATED_NOTIFICATION = "mpush_create_notification"
    val ACTION_CLICKED_NOTIFICATION = "mpush_clicked_notification"

    override fun onMessageReceived(message: RemoteMessage) {
        val body: String? = message.data["body"]
        var title: String? = message.data["title"]
        var sound: String? = message.data["sound"]

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

                    val uri = Uri.parse(mediaUrl)
                    val lastPath = uri.lastPathSegment

                    if (lastPath != null) {
                        val extension = lastPath.substring(lastPath.lastIndexOf("."))
                        if (extension != null) {
                            if (extension.contains("png") ||
                                extension.contains("jpg") ||
                                extension.contains("jpeg")
                            ) {
                                image = mediaUrl
                            }
                        }
                    }
                }
            }
        }

        sendNotification(message.data, title!!, body, image, sound)
    }

    fun sendNotification(
        map: Map<String, String>,
        title: String,
        body: String?,
        image: String?,
        sound: String?
    ) {
        val prefs = Utils.getSharedPreferences(applicationContext)
        val channelId = prefs?.getString("channelId", null)
        val channelName = prefs?.getString("channelName", null)
        val channelDescription = prefs?.getString("channelDescription", null)

        val icon = prefs?.getString("icon", null)

        if (channelId != null) {

            val realBody = body ?: ""

            val gson = Gson()

            var iconResource: Int? = null
            if (icon != null) {
                iconResource = Utils.getDrawableResourceId(applicationContext, icon)
            }

            val notificationID = Random.nextInt()
            val mNotificationManager =
                applicationContext.getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            val intent = Utils.getLauncherActivity(applicationContext)
            intent?.action = ACTION_CLICKED_NOTIFICATION
            intent?.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            intent?.putExtra("map", gson.toJson(map))

            val contentIntent = PendingIntent.getActivity(
                applicationContext,
                notificationID,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )

            var notificationBuilder = NotificationCompat.Builder(applicationContext, channelId)

            if(sound != null){
                val nameWithoutExtension = File(sound).nameWithoutExtension

                val uri =
                    Uri.parse("android.resource://" + applicationContext.packageName + "/" + Utils.getRawResourceId(applicationContext, nameWithoutExtension))
                if((uri != null) && (Utils.getRawResourceId(applicationContext, nameWithoutExtension) != 0)) {
                    if(Build.VERSION.SDK_INT < 26){
                        notificationBuilder.setSound(uri)
                    }else{
                        Utils.createTempSoundNotificationChannelPush(applicationContext,
                            channelId + "_" + nameWithoutExtension,
                            channelName + " " + nameWithoutExtension,
                            channelDescription + " " + nameWithoutExtension,
                            uri)
                        notificationBuilder = NotificationCompat.Builder(applicationContext, channelId + "_" + nameWithoutExtension)
                    }
                }
            }

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
                    notificationBuilder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .setSummaryText(realBody)
                            .bigPicture(bitmap)
                    )
                } else {
                    notificationBuilder.setStyle(
                        NotificationCompat.BigTextStyle().bigText(realBody)
                    )
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