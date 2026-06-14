import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  static Future<void> scheduleCheckInReminder() async {
    await _plugin.periodicallyShow(
      0,
      'GhostKey Check-in',
      'Are you okay? Tap to confirm.',
      RepeatInterval.daily,
      null,
    );
  }
}