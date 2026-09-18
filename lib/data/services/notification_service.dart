import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'db_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  // إرسال إشعار التقرير اليومي وتلخيص الإنجاز
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
      channelDescription: 'إشعار يومي يلخص المهام المنجزة والمتبقية',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      101,
      'تقرير الإنجاز اليومي 📊',
      'أنجزت $completedCount مهام، والمتبقي $remainingCount مهام. اضغط للمتابعة!',
      details,
    );
  }

  // حفظ وقت التنبيه المفضل
  static Future<void> saveReportTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('report_hour', hour);
    await prefs.setInt('report_minute', minute);
  }

  static Future<Map<String, int>> getReportTime() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt('report_hour') ?? 22, // 10 مساء افتراضياً
      'minute': prefs.getInt('report_minute') ?? 0,
    };
  }
}
