package com.mumble.mpush

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** MpushPlugin */
public class MpushPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "mpush")
    channel.setMethodCallHandler(this);
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "mpush")
      channel.setMethodCallHandler(MpushPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "requestToken") {
      //TODO: request the token and call onToken to return it
    } else if (call.method == "launchNotification") {
      //TODO: return the launch notification map if present
    } else {
      result.notImplemented()
    }

    /// TODO: when notification arrives the plugin should show it (even downloading the image) and call
    /// the channel method pushArrived

    // TODO: when a push is tapped the plugin should call pushTapped
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
