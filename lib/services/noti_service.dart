import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get initialized => _isInitialized;

  // INITIALIZATION
  Future<void> initNotification() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // iOS: IOSInitializationSettings(),
    );

    await notificationsPlugin.initialize(initializationSettings);

    // Request notification permissions
    if (await Permission.notification.request().isGranted) {
      print('Notification permission granted');
    } else {
      print('Notification permission denied');
    }

    _isInitialized = true;
  }

  // NOTIFICATION DETAILS SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel_description',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher', // Ensure the icon is set correctly
      ),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    await notificationsPlugin.show(
      id ?? 0,
      title,
      body,
      notificationDetails(),
    );
  }

  // SCHEDULE NOTIFICATION
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    int? id, // task id
  }) async {
    final scheduledDateTime = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute);

    print('Scheduling notification for $scheduledDateTime');

    // Schedule the notification
    await notificationsPlugin.zonedSchedule(
      id ?? 0,
      title,
      body,
      scheduledDateTime,
      notificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Scheduled notification for $scheduledDateTime');
  }

  // CANCEL ALL NOTIFICATION
  Future<void> cancelAllNotification() async {
    await notificationsPlugin.cancelAll();
    print('Canceled all notifications!');
  }

  // CANCEL NOTIFICATION
  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    print('Canceled notification with id: $id');
  }
}