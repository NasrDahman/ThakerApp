import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'db_service.dart';
import 'package:isar/isar.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Aden'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  static Future<void> showImmediateNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_report_channel',
      'التقرير اليومي',
      channelDescription: 'قناة إشعارات الإنجاز والمهام اليومية',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> scheduleDailyReport(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tasks = await DBService.isar.tasks.where().findAll();
    final done = tasks.where((t) => t.isCompleted).length;
    final remaining = tasks.length - done;

    final body = tasks.isEmpty
        ? 'لا توجد مهام مسجلة اليوم. استغل يومك في التعلم!'
        : 'أنجزت $done من المهام، ومتبقي لديك $remaining مهام.';

    const androidDetails = AndroidNotificationDetails(
      'daily_report_channel',
      'التقرير اليومي',
      channelDescription: 'قناة إشعارات الإنجاز والمهام اليومية',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notificationsPlugin.zonedSchedule(
      100,
      'تقرير الإنجاز اليومي 📊',
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
