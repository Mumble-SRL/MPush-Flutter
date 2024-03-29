import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mpush/mp_android_notifications_settings.dart';
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush_api.dart';

import 'package:mpush/mpush_notification_permission.dart';

export 'package:mpush/mpush_notification_permission.dart';

/// The MPush plugin, used to interact with MPush
class MPush {
  static const MethodChannel _channel = MethodChannel('mpush');

  /// The api token of the MPush project
  static set apiToken(String apiToken) {
    MPushApi.apiToken = apiToken;
  }

  /// The api token of the MPush project
  static String get apiToken => MPushApi.apiToken;

//region onToken
  static Function(String)? _onToken;

  /// Callback called when a token is retrieved from APNS or FCM
  static set onToken(Function(String)? value) {
    _initializeMethodCall();
    _onToken = value;
  }

  /// Callback called when a token is retrieved from APNS or FCM
  static Function(String)? get onToken => _onToken;

//endregion

  static Function(Map<String, dynamic>)? _onNotificationArrival;
  static Function(Map<String, dynamic>)? _onNotificationTap;

  static Function(Map<String, dynamic>)? get onNotificationArrival =>
      _onNotificationArrival;

  static Function(Map<String, dynamic>)? get onNotificationTap =>
      _onNotificationTap;

  /// The notification that launched the app, if present, otherwise `null`.
  static Future<Map<String, dynamic>?> launchNotification() async {
    dynamic result = await _channel.invokeMethod('launchNotification');
    if (result == null) {
      return result;
    } else if (result is Map<String, dynamic>) {
      return result;
    } else if (result is Map) {
      return Map<String, dynamic>.from(result);
    } else if (result is String) {
      return json.decode(result);
    }
    return null;
  }

  /// Configures the MPush plugin with the callbacks.
  ///
  /// @param onNotificationArrival Called when a push notification arrives.
  /// @param onNotificationTap Called when a push notification is tapped.
  /// @param androidNotificationsSettings Settings for the android notification.
  static Future<void> configure({
    required Function(Map<String, dynamic>) onNotificationArrival,
    required Function(Map<String, dynamic>) onNotificationTap,
    required MPAndroidNotificationsSettings androidNotificationsSettings,
  }) async {
    _initializeMethodCall();
    _onNotificationArrival = onNotificationArrival;
    _onNotificationTap = onNotificationTap;
    await _channel.invokeMethod(
      'configure',
      androidNotificationsSettings.toMethodChannelArguments(),
    );
  }

  /// Adds custom replacements map to the notifications.
  /// Map keys are the strings to replace with the values
  /// Saved data persists between app openings
  static Future<void> addCustomReplacements({
    required Map<String, String>? customData,
  }) async {
    try {
      await _channel.invokeMethod(
        'add_custom_replacements',
        customData,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Removes previously custom replacements map to the notifications.
  static Future<void> removeCustomReplacements() async {
    try {
      await _channel.invokeMethod(
        'remove_custom_replacements',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get the current saved custom replacements. It will be null if no map has been saved
  static Future<Map<String, String>?> getCustomReplacements() async {
    try {
      dynamic result = await _channel.invokeMethod(
        'get_custom_replacements',
      );

      if (result == null) {
        return result;
      } else if (result is Map<String, String>?) {
        return result;
      } else if (result is Map) {
        return Map<String, String>.from(result);
      } else if (result is String) {
        return json.decode(result);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Returns the current push notification permission status
  static Future<MPushNotificationPermission> notificationPermission() async {
    try {
      dynamic result = await _channel.invokeMethod(
        'get_notification_permission_status',
      );

      if (result is String) {
        return MPushNotificationPermissionUtilities.permissionFromString(
                result) ??
            MPushNotificationPermission.undefined;
      } else {
        return MPushNotificationPermission.undefined;
      }
    } catch (e) {
      rethrow;
    }
  }
//region APIs

  /// Register a device token.
  ///
  /// @param token: the token for this device, typically coming from the onToken` callback`.
  /// @returns A future that completes once the registration is successful.
  static Future<void> registerDevice(String token) async {
    return MPushApi.registerDevice(token);
  }

  /// Register the current device to a topic.
  ///
  /// @param topic The topic you will register to.
  /// @returns A future that completes once the registration is successful.
  static Future<void> registerToTopic(MPTopic topic) async {
    return MPushApi.registerToTopics([topic]);
  }

  /// Register the current device to an array of topics.
  ///
  /// @param topics The array of topics you will register to.
  /// @returns A future that completes once the registration is successful.
  static Future<void> registerToTopics(List<MPTopic> topics) async {
    return MPushApi.registerToTopics(topics);
  }

  /// Unregister the current device from a topic, the topic is matched using the code of the topic.
  ///
  /// @param topics The topic you will unregister from.
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromTopic(String topic) async {
    return MPushApi.unregisterFromTopics([topic]);
  }

  /// Unregister the current device from an array of topics, the topics are matched using the code of the topic.
  ///
  /// @param topics The array of topics you will unregister from.
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromTopics(List<String> topics) async {
    return MPushApi.unregisterFromTopics(topics);
  }

  /// Unregister the current device from all topics it is registred to.
  ///
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromAllTopics() async {
    return MPushApi.unregisterFromAllTopics();
  }

//endregion

  /// Requests the token to APNS & GCM.
  ///
  /// This will not return the token, use the onToken callback to
  /// retrieve the token once the registration is completed with success.
  ///
  /// @returns A future that completes once the registration is started successfully.
  static Future<void> requestToken() async {
    await _channel.invokeMethod('requestToken');
  }

  //region method call handler
  static Future<dynamic> _mPushHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onToken':
        if (methodCall.arguments is String && onToken != null) {
          onToken!(methodCall.arguments);
        }
        break;
      case 'pushArrived':
        if (_onNotificationArrival != null) {
          _callOnNotificationArrival(
            methodCall.arguments,
            _onNotificationArrival!,
          );
        }
        break;
      case 'pushTapped':
        if (_onNotificationTap != null) {
          _callOnNotificationTap(
            methodCall.arguments,
            _onNotificationTap!,
          );
        }
        break;
      default:
        debugPrint('${methodCall.method} not implemented');
        return;
    }
  }

  /// Parses the `arguments` and calls the `onNotificationArrival` callback.
  static void _callOnNotificationArrival(
    dynamic arguments,
    Function(Map<String, dynamic>) onNotificationArrival,
  ) {
    if (arguments is Map<String, dynamic>) {
      onNotificationArrival(arguments);
    } else if (arguments is Map) {
      Map<String, dynamic> map = Map<String, dynamic>.from(arguments);
      onNotificationArrival(map);
    } else if (arguments is String) {
      Map<String, dynamic> map = json.decode(arguments);
      onNotificationArrival(map);
    }
  }

  /// Parses the `arguments` and calls the `onNotificationTap` callback.
  static void _callOnNotificationTap(
    dynamic arguments,
    Function(Map<String, dynamic>) onNotificationTap,
  ) {
    if (arguments is Map<String, dynamic>) {
      onNotificationTap(arguments);
    } else if (arguments is Map) {
      Map<String, dynamic> map = Map<String, dynamic>.from(arguments);
      onNotificationTap(map);
    } else if (arguments is String) {
      Map<String, dynamic> map = json.decode(arguments);
      onNotificationTap(map);
    }
  }

  /// If method call has been initialized or not
  static bool _methodCallInitialized = false;

  /// Initialize the callbacks from the native side to dart
  static Future<void> _initializeMethodCall() async {
    if (!_methodCallInitialized) {
      _methodCallInitialized = true;
      _channel.setMethodCallHandler(_mPushHandler);
    }
  }
}
