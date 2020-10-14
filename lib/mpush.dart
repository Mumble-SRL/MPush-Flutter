import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush_api.dart';

/// The MPush plugin, used to interact with MPush
class MPush {
  static const MethodChannel _channel = const MethodChannel('mpush');

  /// The api token of the MPush project
  static set apiToken(String apiToken) {
    MPushApi.apiToken = apiToken;
  }

  /// The api token of the MPush project
  static get apiToken => MPushApi.apiToken;

//region onToken
  static Function(String) _onToken;

  /// Callback called when a token is retrieved from APNS or FCM
  static set onToken(Function(String) value) {
    _initializeMethodCall();
    _onToken = value;
  }

  /// Callback called when a token is retrieved from APNS or FCM
  static Function(String) get onToken => _onToken;
//endregion

  static Function(Map<String, dynamic>) _onNotificationArrival;
  static Function(Map<String, dynamic>) _onNotificationTap;

  /// The notification that launched the app, if present, otherwise `null`.
  static Future<Map<String, dynamic>> launchNotification() async {
    return _channel.invokeMethod('launchNotification');
  }

  /// Configures the MPush plugin with the callbacks.
  ///
  /// @param onNotificationArrival: called when a push notification arrives.
  /// @param onNotificationTap: called when a push notification is tapped.
  static Future<void> configure({
    @required Function(Map<String, dynamic>) onNotificationArrival,
    @required Function(Map<String, dynamic>) onNotificationTap,
  }) async {
    _initializeMethodCall();
    _onNotificationArrival = onNotificationArrival;
    _onNotificationTap = onNotificationTap;
    await _channel.invokeMethod('configure');
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
    print(methodCall.method);
    print(methodCall.arguments);
    switch (methodCall.method) {
      case 'onToken':
        if (methodCall.arguments is String && onToken != null) {
          onToken(methodCall.arguments);
        }
        break;
      case 'pushArrived':
        if (methodCall.arguments is Map<String, dynamic> &&
            _onNotificationArrival != null) {
          _onNotificationArrival(methodCall.arguments);
        }
        break;
      case 'pushTapped':
        if (methodCall.arguments is Map<String, dynamic> &&
            _onNotificationTap != null) {
          _onNotificationTap(methodCall.arguments);
        }
        break;
      default:
        print('${methodCall.method} not implemented');
        return;
    }
  }

  /// If method call has been initialized or not
  static bool _methodCallInitialized = false;

  /// Called when setting onToken or onPushNotificationTap to initialize the callbacks
  static Future<void> _initializeMethodCall() async {
    if (!_methodCallInitialized) {
      _methodCallInitialized = true;
      _channel.setMethodCallHandler(_mPushHandler);
    }
  }
}
