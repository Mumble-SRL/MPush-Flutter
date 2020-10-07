import 'package:flutter/material.dart';
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush.dart';

void main() {
  MPush.apiToken = "YOUR_TOKEN";

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    _setupMPush();
    super.initState();
  }

  _setupMPush() {
    MPush.onToken = (token) async {
      print("Token received $token");
      await MPush.registerDevice(token).catchError((error) {});
      await MPush.registerToTopic(MPTopic(code: 'Test'));
    };
    MPush.onNotificationArrival = (notification) {
      print("Notification arrived: $notification");
    };
    MPush.onNotificationTap = (notification) {
      print("Notification tapped: $notification");
    };

    MPush.requestToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(),
      ),
    );
  }
}
