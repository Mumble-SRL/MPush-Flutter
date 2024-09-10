import 'package:flutter/material.dart';
import 'package:mpush/mp_android_notifications_settings.dart';
import 'package:mpush/mp_topic.dart';
import 'package:mpush/mpush.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
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
      debugPrint("Token received $token");
      await MPush.registerDevice(token).catchError(
        (error) => debugPrint(error),
      );
      await MPush.registerToTopic(const MPTopic(code: 'Topic')).catchError(
        (error) => debugPrint(error),
      );
      debugPrint('Registered');
    };

    MPush.configure(
      onNotificationArrival: (notification) {
        debugPrint("Notification arrived: $notification");
      },
      onNotificationTap: (notification) {
        debugPrint("Notification tapped: $notification");
      },
      androidNotificationsSettings: const MPAndroidNotificationsSettings(
        channelId: 'mpush_example',
        channelName: 'mpush',
        channelDescription: 'mpush',
        icon: '@mipmap/icon_notif',
      ),
    );

    Map<String, dynamic>? launchNotification = await MPush.launchNotification();
    debugPrint(launchNotification?.toString());
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
                child: const Text('Request token'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _setCustomReplacements(),
                child: const Text('Set custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _removeCustomReplacements(),
                child: const Text('Remove custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _printCustomReplacements(),
                child: const Text('Print custom replacements'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _printNotificationPermissionStatus(),
                child: const Text('Print notification permission status'),
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
    debugPrint(customReplacements?.toString());
  }

  Future<void> _printNotificationPermissionStatus() async {
    MPushNotificationPermission? permissionStatus =
        await MPush.notificationPermission();
    debugPrint(permissionStatus.toString());
  }
}
