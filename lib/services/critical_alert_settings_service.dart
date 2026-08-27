import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CriticalAlertSettingsService {
  CriticalAlertSettingsService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<bool> hasNotificationPolicyAccess() async {
    final AndroidFlutterLocalNotificationsPlugin? plugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await plugin?.hasNotificationPolicyAccess() ?? false;
  }

  static Future<bool> requestNotificationPolicyAccess() async {
    final AndroidFlutterLocalNotificationsPlugin? plugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await plugin?.requestNotificationPolicyAccess() ?? false;
  }
}
