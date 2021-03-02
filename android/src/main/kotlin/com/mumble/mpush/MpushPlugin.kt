package com.mumble.mpush

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import androidx.annotation.NonNull
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

class MpushPlugin : FlutterPlugin, BroadcastReceiver(), PluginRegistry.NewIntentListener, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var mainActivity: Activity? = null
    private var applicationContext: Context? = null
    private var launchIntent: Intent? = null

    val ACTION_CREATED_NOTIFICATION = "mpush_create_notification"
    val ACTION_CLICKED_NOTIFICATION = "mpush_clicked_notification"

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.flutterEngine.dartExecutor, "mpush")
        channel.setMethodCallHandler(this)
        applicationContext = binding.applicationContext

        val intentFilter = IntentFilter()
        intentFilter.addAction(ACTION_CREATED_NOTIFICATION)
        intentFilter.addAction(ACTION_CLICKED_NOTIFICATION)
        LocalBroadcastManager.getInstance(binding.applicationContext).registerReceiver(this, intentFilter)
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

    companion object {

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val plugin = MpushPlugin()
            val channel = MethodChannel(registrar.messenger(), "mpush")
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "requestToken" -> requestFirebaseToken(result)

            "configure" -> {
                setConfiguration(call.arguments as Map<String, Any>)
            }

            "launchNotification" -> {
                getNotificationAppLaunchDetails(result)
            }

            else -> result.notImplemented()
        }
    }

    private fun setConfiguration(map: Map<String, Any>) {
        if(applicationContext != null){
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

            Utils.createNotificationChannelPush(applicationContext!!, channelId, channelName, channelDescription)
        }
    }

    private fun requestFirebaseToken(result: Result) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener(OnCompleteListener { task ->
            if (!task.isSuccessful) {
                return@OnCompleteListener
            }

            val token = task.result
            channel.invokeMethod("onToken", token)
        })

        result.success(true)
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
        val notificationLaunchedApp = mainActivity != null && ACTION_CLICKED_NOTIFICATION.equals(mainActivity!!.intent.action) && !launchedActivityFromHistory(mainActivity!!.intent)
        if (notificationLaunchedApp) {
            payload = launchIntent?.getStringExtra("map")
        }

        result.success(payload)
    }
}
