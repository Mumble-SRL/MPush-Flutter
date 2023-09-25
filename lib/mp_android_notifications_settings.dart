/// Notifications settings for the Android part
class MPAndroidNotificationsSettings {
  /// The channel id
  final String channelId;

  /// The channel name
  final String channelName;

  /// The channel description
  final String channelDescription;

  /// Specifies the default icon for notifications.
  final String icon;

  /// Initializes a new android notification settings
  const MPAndroidNotificationsSettings({
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
