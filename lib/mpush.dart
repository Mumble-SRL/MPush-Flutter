import 'dart:async';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush_exception.dart';

class MPush {
  static const MethodChannel _channel = const MethodChannel('mpush');

  static String get _endpoint => 'app.mpush.cloud';
  static String apiToken;

  static Function(String) onToken;
  static Function(Map<String, dynamic>) onNotificationArrival;
  static Function(Map<String, dynamic>) onNotificationTap;

//region APIs
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

  static Future<void> registerToTopic(MPTopic topic) async {
    return registerToTopics([topic]);
  }

  static Future<void> registerToTopics(List<MPTopic> topics) async {
    Map<String, String> apiParameters = {};
    apiParameters.addAll(await _defaultParameters());
    List<Map<String, dynamic>> topicsDictionaries =
    topics.map((t) => t.toApiDictionary()).toList();
    apiParameters['topics'] = json.encode(topicsDictionaries);
    print(apiParameters);
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

  static Future<void> unregisterFromTopic(String topic) async {
    return unregisterFromTopics([topic]);
  }

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

  /// Requests the token to APNS & GCM
  static Future<void> requestToken() async {
    await _initializeMethodCall();
    await _channel.invokeMethod('requestToken');
  }

//region method call handler
  static Future<dynamic> _mPushHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'onToken':
        if (methodCall.arguments is String && onToken != null) {
          onToken(methodCall.arguments);
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
