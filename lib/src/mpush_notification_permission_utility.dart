import 'package:mpush/mpush_notification_permission.dart';

/// Utility class to manage [MPushNotificationPermission]
class MPushNotificationPermissionUtility {
  /// Returns a [MPushNotificationPermission] from an input [String]
  static MPushNotificationPermission? permissionFromString(String permission) {
    switch (permission) {
      case 'granted':
        return MPushNotificationPermission.granted;
      case 'denied':
        return MPushNotificationPermission.denied;
      case 'undefined':
        return MPushNotificationPermission.undefined;
      case 'provisional':
        return MPushNotificationPermission.provisional;
      case 'ephemeral':
        return MPushNotificationPermission.ephemeral;
      default:
        return null;
    }
  }
}
