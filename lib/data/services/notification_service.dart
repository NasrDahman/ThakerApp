import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'db_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // طلب إذن الإشعارات لأندرويد 13 فما فوق
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // جدولة التقرير بناءً على الإعدادات المحفوظة
    final savedTime = await getReportTime();
    await scheduleDailyReport(savedTime['hour']!, savedTime['minute']!);
  }

  static Future<void> scheduleDailyReport(int hour, int minute) async {
    await _notifications.cancel(101); // إلغاء أي جدولة سابقة

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'daily_report_channel',
      'التقرير اليومي',
      channelDescription: 'إشعار يومي يلخص المهام المنجزة والمتبقية',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.zonedSchedule(
      101,
      'تقرير الإنجاز اليومي 📊',
      'حان موعد مراجعة مهامك اليومية، تفقد ما أنجزته وما تم ترحيله!',
      tzDateTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showDailyReportNotification() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final completedCount = await DBService.isar.tasks
        .filter()
        .createdAtBetween(startOfDay, endOfDay)
        .isCompletedEqualTo(true)
        .count();

    final remainingCount = await DBService.isar.tasks
        .filter()
        .createdAtBetween(startOfDay, endOfDay)
        .isCompletedEqualTo(false)
        .count();

    const androidDetails = AndroidNotificationDetails(
      'daily_report_channel',
      'التقرير اليومي',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _notifications.show(
      102,
      'تقرير الإنجاز اليومي 📊',
      'أنجزت $completedCount مهام، والمتبقي $remainingCount مهام.',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> saveReportTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('report_hour', hour);
    await prefs.setInt('report_minute', minute);
    await scheduleDailyReport(hour, minute);
  }

  static Future<Map<String, int>> getReportTime() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt('report_hour') ?? 22,
      'minute': prefs.getInt('report_minute') ?? 0,
    };
  }
}
