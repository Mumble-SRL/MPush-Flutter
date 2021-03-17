/// Notifications settings for the Android part
class MPAndroidNotificationsSettings {
  /// The channel id
  String channelId;

  /// The channel name
  String channelName;

  /// The channel description
  String channelDescription;

  /// Specifies the default icon for notifications.
  String icon;

  /// Initializes a new android notification settings
  MPAndroidNotificationsSettings({
    required this.channelId,
    required this.icon,
    required this.channelName,
    required this.channelDescription,
  });

  /// Convert this object to a map that can be sent to the method channel
  Map<String, dynamic> toMethodChannelArguments() {
    return {
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'icon': icon,
    };
  }
}
