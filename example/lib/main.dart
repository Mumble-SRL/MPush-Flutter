import 'package:flutter/material.dart';
import 'package:mpush/mp_android_notifications_settings.dart';
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
    _initMPush();
    super.initState();
  }

  _initMPush() async {
    MPush.apiToken = 'YOUR_API_KEY';
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

    MPush.configure(
      onNotificationArrival: (notification) {
        print("Notification arrived: $notification");
      },
      onNotificationTap: (notification) {
        print("Notification tapped: $notification");
      },
      androidNotificationsSettings: MPAndroidNotificationsSettings(
        channelId: 'mpush_example',
        channelName: 'mpush',
        channelDescription: 'mpush',
        icon: '@mipmap/icon_notif',
      ),
    );

    Map<String, dynamic>? launchNotification = await MPush.launchNotification();
    print(launchNotification);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MPush Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => MPush.requestToken(),
                child: Text('Request token'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _setCustomReplacements(),
                child: Text('Set custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _removeCustomReplacements(),
                child: Text('Remove custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _printCustomReplacements(),
                child: Text('Print custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _printNotificationPermissionStatus(),
                child: Text('Print notification permission status'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setCustomReplacements() async {
    await MPush.addCustomReplacements(
      customData: {'Test Key': 'Test Value'},
    );
  }

  Future<void> _removeCustomReplacements() async {
    await MPush.removeCustomReplacements();
  }

  Future<void> _printCustomReplacements() async {
    Map<String, String>? customReplacements =
        await MPush.getCustomReplacements();
    print(customReplacements);
  }

  Future<void> _printNotificationPermissionStatus() async {
    MPushNotificationPermission? permissionStatus =
        await MPush.notificationPermission();
    print(permissionStatus);
  }
}
