package com.mumble.mpush

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** MpushPlugin */
class MpushPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var mainActivity: Activity? = null
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.flutterEngine.dartExecutor, "mpush")
        channel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.mainActivity = binding.activity
        this.applicationContext = binding.activity.applicationContext
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.mainActivity = null
        this.applicationContext = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.mainActivity = binding.activity
        this.applicationContext = binding.activity.applicationContext
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
            "launchNotification" -> {
            }//TODO: return the launch notification map if present
            else -> result.notImplemented()
        }

        /// TODO: when notification arrives the plugin should show it (even downloading the image) and call
        /// the channel method pushArrived

        // TODO: when a push is tapped the plugin should call pushTapped
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
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

}
