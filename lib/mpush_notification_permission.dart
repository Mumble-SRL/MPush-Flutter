/// Current status for the notification permission
enum MPushNotificationPermission {
  /// Notification permission has been granted.
  granted,

  /// Notification permission has been denied.
  denied,

  /// Notification permission is undefined.
  undefined,

  /// The application is provisionally authorized to post noninterruptive user notifications, available only on iOS.
  provisional,

  /// The app is authorized to schedule or receive notifications for a limited amount of time, available only on iOS.
  ephemeral,
}