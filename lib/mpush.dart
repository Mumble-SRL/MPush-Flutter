import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush_exception.dart';

/// The MPush plugin, used to interact with MPush
class MPush {
  static const MethodChannel _channel = const MethodChannel('mpush');

  /// Mpush endpoint
  static String get _endpoint => 'app.mpush.cloud';

  /// The api token of the MPush project
  static String apiToken;

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
    Map<String, String> apiParameters = {};
    apiParameters.addAll(await _defaultParameters());
    apiParameters['token'] = token;

    String apiName = 'api/tokens';

    var requestBody = json.encode(apiParameters);

    Map<String, String> headers = _defaultHeaders(contentTypeJson: true);

    var uri = Uri.https(_endpoint, apiName);

    http.Response response = await http.post(
      uri,
      headers: headers,
      body: requestBody,
    );

    _checkResponse(response.body);
  }

  /// Register the current device to a topic.
  ///
  /// @param topic The topic you will register to.
  /// @returns A future that completes once the registration is successful.
  static Future<void> registerToTopic(MPTopic topic) async {
    return registerToTopics([topic]);
  }

  /// Register the current device to an array of topics.
  ///
  /// @param topics The array of topics you will register to.
  /// @returns A future that completes once the registration is successful.
  static Future<void> registerToTopics(List<MPTopic> topics) async {
    Map<String, String> apiParameters = {};
    apiParameters.addAll(await _defaultParameters());
    List<Map<String, dynamic>> topicsDictionaries =
        topics.map((t) => t.toApiDictionary()).toList();
    apiParameters['topics'] = json.encode(topicsDictionaries);

    String apiName = 'api/register';

    var requestBody = json.encode(apiParameters);

    Map<String, String> headers = _defaultHeaders(contentTypeJson: true);

    var uri = Uri.https(_endpoint, apiName);

    http.Response response = await http.post(
      uri,
      headers: headers,
      body: requestBody,
    );
    _checkResponse(response.body);
  }

  /// Unregister the current device from a topic, the topic is matched using the code of the topic.
  ///
  /// @param topics The topic you will unregister from.
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromTopic(String topic) async {
    return unregisterFromTopics([topic]);
  }

  /// Unregister the current device from an array of topics, the topics are matched using the code of the topic.
  ///
  /// @param topics The array of topics you will unregister from.
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromTopics(List<String> topics) async {
    Map<String, String> apiParameters = {};
    apiParameters.addAll(await _defaultParameters());
    apiParameters['topics'] = json.encode(topics);

    String apiName = 'api/unregister';

    var requestBody = json.encode(apiParameters);

    Map<String, String> headers = _defaultHeaders(contentTypeJson: true);

    var uri = Uri.https(_endpoint, apiName);

    http.Response response = await http.post(
      uri,
      headers: headers,
      body: requestBody,
    );

    _checkResponse(response.body);
  }

  /// Unregister the current device from all topics it is registred to.
  ///
  /// @returns A future that completes once the registration is successful.
  static Future<void> unregisterFromAllTopics() async {
    Map<String, String> apiParameters = await _defaultParameters();

    String apiName = 'api/unregister-all';

    var requestBody = json.encode(apiParameters);

    Map<String, String> headers = _defaultHeaders(contentTypeJson: true);

    var uri = Uri.https(_endpoint, apiName);

    http.Response response = await http.post(
      uri,
      headers: headers,
      body: requestBody,
    );

    _checkResponse(response.body);
  }

  static Map<String, String> _defaultHeaders({contentTypeJson: false}) {
    Map<String, String> headers = {
      'X-MPush-Version': '2',
      'X-MPush-Token': apiToken,
      'Accept': 'application/json',
    };
    if (contentTypeJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  static Future<Map<String, String>> _defaultParameters() async {
    Map<String, String> defaultParameters = {
      'platform': Platform.isIOS ? 'ios' : 'and',
    };
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      defaultParameters['device_id'] = androidInfo.androidId;
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      defaultParameters['device_id'] = iosInfo.identifierForVendor;
    }
    return defaultParameters;
  }

  static _checkResponse(String response) {
    final responseJson = json.decode(response);
    Map<String, dynamic> responseDecoded = responseJson as Map<String, dynamic>;
    int statusCode = responseDecoded["status_code"] as int ?? -1;
    if (statusCode == 0) {
      return;
    } else {
      String errorString = _errorString(responseDecoded);
      throw MPushException(
        errorString ?? "There was an error, retry later",
        statusCode: statusCode,
      );
    }
  }

  static String _errorString(Map<String, dynamic> responseDecoded) {
    String message = responseDecoded["message"] as String;
    if (responseDecoded["errors"] != null) {
      String errorsString = '';
      Map<String, dynamic> errors = responseDecoded["errors"];
      for (String key in errors.keys) {
        dynamic value = errors[key];
        if (value is String) {
          errorsString += errorsString == '' ? value : '\n$value';
        } else if (value is List) {
          for (var v in value) {
            if (v is String) {
              errorsString += errorsString == '' ? v : '\n$v';
            }
          }
        }
      }
      if (errorsString != '') {
        return errorsString;
      }
    }
    return message;
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
