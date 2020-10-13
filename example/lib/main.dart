import 'package:flutter/material.dart';
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush.dart';

void main() {
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

  _setupMPush() async {
    MPush.apiToken = '5WcAhfzt1QTE2N7aGvcGehFFjooZd2SyByys8vAf';
    MPush.onToken = (token) async {
      print("Token received $token");
      await MPush.registerDevice(token).catchError(
        (error) => print(error),
      );
      await MPush.registerToTopic(MPTopic(code: 'Topic')).catchError(
        (error) => print(error),
      );
      print('Registered');
    };
    MPush.onNotificationArrival = (notification) {
      print("Notification arrived: $notification");
    };
    MPush.onNotificationTap = (notification) {
      print("Notification tapped: $notification");
    };

    MPush.requestToken();

    Map<String, dynamic> launchNotification = await MPush.launchNotification();
    print(launchNotification);
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
