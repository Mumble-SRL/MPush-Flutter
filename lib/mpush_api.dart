import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;

import 'mp_topic.dart';
import 'mpush_exception.dart';

/// The class that handles api calls to MPush
class MPushApi {
  /// Mpush endpoint
  static String get _endpoint => 'app.mpush.cloud';

  /// The api token of the MPush project
  static String apiToken = '';

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
    int statusCode = -1;
    if (responseDecoded["status_code"] is int) {
      statusCode = responseDecoded["status_code"];
    }
    if (statusCode == 0) {
      return;
    } else {
      String errorString = _errorString(responseDecoded);
      throw MPushException(
        errorString,
        statusCode: statusCode,
      );
    }
  }

  static String _errorString(Map<String, dynamic> responseDecoded) {
    String message = 'There was an error, retry later';
    if (responseDecoded["message"] is String) {
      message = responseDecoded["message"];
    }
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
}
