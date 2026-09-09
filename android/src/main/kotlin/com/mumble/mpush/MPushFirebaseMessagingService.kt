package com.mumble.mpush

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.gson.Gson
import org.json.JSONObject
import kotlin.random.Random
import java.io.File
import java.util.Locale

class MPushFirebaseMessagingService : FirebaseMessagingService() {

    val ACTION_CLICKED_NOTIFICATION = "mpush_clicked_notification"

    // Logs only from a debuggable build of the host app: Log.d is not stripped
    // from release, and these lines describe notification payloads.
    private fun log(message: String) {
        val debuggable =
            applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (debuggable) Log.d("MPush", message)
    }

    override fun onNewToken(token: String) {
        log("🔔 onNewToken called")
        super.onNewToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        log("🔔 onMessageReceived called")
        // Keys only: the payload carries titles, bodies and deep links, and
        // Android's log is readable by anything with the right permission.
        log("🔔 Message keys: ${message.data.keys}")
        
        var body: String? = message.data["body"]
        var title: String? = message.data["title"]
        var sound: String? = message.data["sound"]

        log("🔔 has title: ${title != null}, has body: ${body != null}")

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

                // App-specific bilingual notifications: override title/body with the
                // localized payload keys based on the app language (App Group override
                // key `#canossa_language#`, falling back to the device locale).
                var isItalian = Locale.getDefault().language == "it"
                val savedLocale =
                    Utils.getCustomReplacements(applicationContext)?.get("#canossa_language#")
                if (savedLocale != null) {
                    isItalian = savedLocale.lowercase() == "it"
                }
                if (isItalian) {
                    if (Utils.isJSONOk(jCustom, "titleita")) title = jCustom["titleita"] as String?
                    if (Utils.isJSONOk(jCustom, "textita")) body = jCustom["textita"] as String?
                } else {
                    if (Utils.isJSONOk(jCustom, "titleeng")) title = jCustom["titleeng"] as String?
                    if (Utils.isJSONOk(jCustom, "texteng")) body = jCustom["texteng"] as String?
                }

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

        if (title.isNullOrEmpty()) {
            title = Utils.getApplicationName(applicationContext)
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

            val titleWithCustom = Utils.getStringWithCustomReplacements(applicationContext, title)
            val bodyWithCustom = Utils.getStringWithCustomReplacements(applicationContext, realBody)

            val gson = Gson()

            var iconResource: Int? = null
            if (icon != null) {
                iconResource = Utils.getNotificationIconResourceId(applicationContext, icon)
                if (iconResource == 0) {
                    log("Notification icon not found: $icon")
                    iconResource = null
                }
            }

            if (iconResource == null) {
                iconResource = applicationContext.applicationInfo.icon
                if (iconResource == 0) {
                    iconResource = applicationContext.packageManager
                        .getApplicationInfo(applicationContext.packageName, PackageManager.GET_META_DATA)
                        .icon
                }
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
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
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

            notificationBuilder.setContentTitle(titleWithCustom)
                .setAutoCancel(true)
                .setContentText(bodyWithCustom)
                .setContentIntent(contentIntent)

            if (iconResource != null && iconResource != 0) {
                notificationBuilder.setSmallIcon(iconResource)
            }

            if (image != null) {
                val bitmap = Utils.getBitmapfromUrl(image)
                if (bitmap != null) {
                    notificationBuilder.setStyle(
                        NotificationCompat.BigPictureStyle()
                            .setSummaryText(bodyWithCustom)
                            .bigPicture(bitmap)
                    )
                } else {
                    notificationBuilder.setStyle(
                        NotificationCompat.BigTextStyle().bigText(bodyWithCustom)
                    )
                }
            } else {
                notificationBuilder.setStyle(NotificationCompat.BigTextStyle().bigText(bodyWithCustom))
            }

            MpushEventBus.postNotificationArrived(gson.toJson(map))
            try {
                mNotificationManager.notify(notificationID, notificationBuilder.build())
            } catch (e: Exception) {
                Log.e("MPush", "Unable to show notification", e)
            }
        }
    }
}
