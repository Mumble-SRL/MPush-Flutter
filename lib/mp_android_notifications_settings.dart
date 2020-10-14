import 'package:flutter/foundation.dart';

/// Notifications settings for the Android part
class MPAndroidNotificationsSettings {
  /// The channel id
  String channelId;

  /// Specifies the default icon for notifications.
  String icon;

  /// Initializes a new android notification settings
  MPAndroidNotificationsSettings({
    @required this.channelId,
    @required this.icon,
  });

  /// Convert this object to a map that can be sent to the method channel
  Map<String, dynamic> toMethodChannelArguments() {
    return {
      'channelId': channelId,
      'icon': icon,
    };
  }
}
