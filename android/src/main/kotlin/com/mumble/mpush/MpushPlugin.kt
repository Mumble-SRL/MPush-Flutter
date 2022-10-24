package com.mumble.mpush

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

/** MpushPlugin */

class MpushPlugin : FlutterPlugin, BroadcastReceiver(), PluginRegistry.NewIntentListener,
    PluginRegistry.RequestPermissionsResultListener, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var mainActivity: Activity? = null
    private var applicationContext: Context? = null
    private var launchIntent: Intent? = null

    val ACTION_CREATED_NOTIFICATION = "mpush_create_notification"
    val ACTION_CLICKED_NOTIFICATION = "mpush_clicked_notification"

    private val postNotificationsPermissionCode = 34264

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val plugin = MpushPlugin()
            val channel = MethodChannel(registrar.messenger(), "mpush")
            registrar.addRequestPermissionsResultListener(plugin)
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.flutterEngine.dartExecutor, "mpush")
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext

        val intentFilter = IntentFilter()
        intentFilter.addAction(ACTION_CREATED_NOTIFICATION)
        intentFilter.addAction(ACTION_CLICKED_NOTIFICATION)
        LocalBroadcastManager.getInstance(binding.applicationContext)
            .registerReceiver(this, intentFilter)
        //Log.d("LocalBroadcastManager", "OK")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        LocalBroadcastManager.getInstance(binding.applicationContext).unregisterReceiver(this)
        //Log.d("LocalBroadcastManager", "REMOVED")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.mainActivity = binding.activity
        this.applicationContext = binding.activity.applicationContext
        this.launchIntent = mainActivity?.intent
        binding.addOnNewIntentListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.mainActivity = null
        this.applicationContext = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.mainActivity = binding.activity
        this.applicationContext = binding.activity.applicationContext
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        this.mainActivity = null
        this.applicationContext = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        when (requestCode) {
            postNotificationsPermissionCode -> {
                if (grantResults != null) {
                    val permissionGranted = grantResults.isNotEmpty() &&
                            grantResults[0] == PackageManager.PERMISSION_GRANTED

                    if (permissionGranted) {
                        callFirebaseForToken()
                    }
                }

                return true
            }
        }

        return false
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "requestToken" -> requestFirebaseToken(result)

            "configure" -> {
                setConfiguration(result, call.arguments as Map<String, Any>)
            }

            "launchNotification" -> {
                getNotificationAppLaunchDetails(result)
            }

            "add_custom_replacements" -> {
                addCustomInfo(call.arguments as Map<String, String>)
            }

            "remove_custom_replacements" -> {
                if (applicationContext != null) {
                    Utils.removeCustomReplacements(applicationContext!!)
                } else {
                    result.error("NoContext", "No context", null)
                }
            }

            "get_custom_replacements" -> {
                if (applicationContext != null) {
                    val map = Utils.getCustomReplacements(applicationContext!!)
                    result.success(map)
                } else {
                    result.error("NoContext", "No context", null)
                }
            }

            "get_notification_permission_status" -> getNotificationPermissionStatus(result)

            else -> result.notImplemented()
        }
    }

    private fun setConfiguration(result: Result, map: Map<String, Any>) {
        if (applicationContext != null) {
            val channelId = map["channelId"] as String
            val channelName = map["channelName"] as String
            val channelDescription = map["channelDescription"] as String
            val icon = map["icon"] as String

            val editor = Utils.getSharedPreferencesEditor(applicationContext)
            editor?.putString("channelId", channelId)
            editor?.putString("channelName", channelName)
            editor?.putString("channelDescription", channelDescription)
            editor?.putString("icon", icon)
            editor?.apply()

            Utils.createNotificationChannelPush(
                applicationContext!!,
                channelId,
                channelName,
                channelDescription
            )
            result.success(null)
        }
    }

    private fun getNotificationPermissionStatus(result: Result){
        if (Build.VERSION.SDK_INT >= 33) {
            if(applicationContext != null) {
                val checkPermissionNotification = ContextCompat.checkSelfPermission(
                    applicationContext!!,
                    Manifest.permission.POST_NOTIFICATIONS
                )

                if(checkPermissionNotification == PackageManager.PERMISSION_GRANTED){
                    result.success("granted")
                    return
                }else{
                    result.success("denied")
                    return
                }
            }

            result.success("undefined")
            return
        }

        result.success("granted")
    }

    private fun isNotificationPermissionEnabled(): Boolean{
        if (Build.VERSION.SDK_INT >= 33) {
            if(applicationContext != null) {
                val checkPermissionNotification = ContextCompat.checkSelfPermission(
                    applicationContext!!,
                    Manifest.permission.POST_NOTIFICATIONS
                )

                return checkPermissionNotification == PackageManager.PERMISSION_GRANTED
            }

            return false
        }

        return true
    }

    private fun requestFirebaseToken(result: Result) {
        if (Build.VERSION.SDK_INT >= 33) {
            if ((mainActivity != null) && (applicationContext != null)) {
                if (isNotificationPermissionEnabled()) {
                    callFirebaseForToken()
                    result.success(true)
                } else {
                    ActivityCompat.requestPermissions(
                        mainActivity!!,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        postNotificationsPermissionCode
                    )

                    result.success(true)
                }
            }
        } else {
            callFirebaseForToken()
            result.success(true)
        }
    }

    private fun callFirebaseForToken() {
        FirebaseMessaging.getInstance().token.addOnCompleteListener(OnCompleteListener { task ->
            if (!task.isSuccessful) {
                return@OnCompleteListener
            }

            val token = task.result
            channel.invokeMethod("onToken", token)
        })
    }

    private fun sendNotificationPayloadMessage(intent: Intent): Boolean {
        if (intent.action == ACTION_CLICKED_NOTIFICATION) {
            val payload = intent.getStringExtra("map")
            channel.invokeMethod("pushTapped", payload)
            return true
        }
        return false
    }

    override fun onReceive(context: Context?, intent: Intent) {
        //Log.d("onReceive", "DO")
        val action = intent.action ?: return
        if (action == ACTION_CREATED_NOTIFICATION) {
            //Log.d("onReceive", "ACTION_CREATED_NOTIFICATION")
            val extras = intent.extras ?: return
            val map = extras.getString("map") ?: return
            channel.invokeMethod("pushArrived", map)
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val res: Boolean = sendNotificationPayloadMessage(intent)
        if (res && mainActivity != null) {
            mainActivity!!.intent = intent
        }
        return res
    }

    private fun launchedActivityFromHistory(intent: Intent?): Boolean {
        return intent != null && intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY == Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY
    }

    private fun getNotificationAppLaunchDetails(result: Result) {
        var payload: String? = null
        val notificationLaunchedApp =
            mainActivity != null && ACTION_CLICKED_NOTIFICATION.equals(mainActivity!!.intent.action) && !launchedActivityFromHistory(
                mainActivity!!.intent
            )
        if (notificationLaunchedApp) {
            payload = launchIntent?.getStringExtra("map")
        }

        result.success(payload)
    }

    private fun addCustomInfo(map: Map<String, String>) {
        if (applicationContext != null) {
            if (map != null) {
                Utils.setCustomReplacements(applicationContext!!, map)
            }
        }
    }
}
