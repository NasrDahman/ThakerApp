import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/lecture.dart';
import '../models/task.dart';
import 'db_service.dart';

final studyRepoProvider = Provider((ref) => StudyRepository());

// تيار لمراقبة مهام اليوم العادية
final todayTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return DBService.isar.tasks
      .filter()
      .isPostponedEqualTo(false)
      .createdAtBetween(startOfDay, endOfDay)
      .watch(fireImmediately: true);
});

// تيار لمراقبة المهام المؤجلة
final postponedTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  return DBService.isar.tasks
      .filter()
      .isPostponedEqualTo(true)
      .watch(fireImmediately: true);
});

// تيار لمراقبة محاضرات اليوم الحالي
final todayLecturesProvider = StreamProvider.autoDispose<List<Lecture>>((ref) {
  final currentDay = DateTime.now().weekday;
  return DBService.isar.lectures
      .filter()
      .dayOfWeekEqualTo(currentDay)
      .sortBySlotIndex()
      .watch(fireImmediately: true);
});

class StudyRepository {
  final Isar _isar = DBService.isar;

  // جلب المحاضرات ليوم معين
  Future<List<Lecture>> getLecturesByDay(int dayOfWeek) async {
    return await _isar.lectures
        .filter()
        .dayOfWeekEqualTo(dayOfWeek)
        .sortBySlotIndex()
        .findAll();
  }

  // حفظ أو تحديث محاضرة
  Future<void> saveLecture(Lecture lecture) async {
    await _isar.writeTxn(() async {
      await _isar.lectures.put(lecture);
    });
  }

  // حذف محاضرة
  Future<void> deleteLecture(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.lectures.delete(id);
    });
  }

  // إضافة مهمة جديدة
  Future<void> addTask(String title, {int? linkedLectureId}) async {
    final task = Task()
      ..title = title
      ..createdAt = DateTime.now()
      ..linkedLectureId = linkedLectureId;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  // تبديل حالة إنجاز المهمة
  Future<void> toggleTaskStatus(Task task) async {
    await _isar.writeTxn(() async {
      task.isCompleted = !task.isCompleted;
      await _isar.tasks.put(task);
    });
  }

  // حذف مهمة نهائياً
  Future<void> deleteTask(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(id);
    });
  }

  // فحص وترحيل المهام القديمة غير المكتملة إلى قائمة المؤجلات
  Future<void> checkAndPostponeTasks() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final overdueTasks = await _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .isPostponedEqualTo(false)
        .createdAtLessThan(startOfToday)
        .findAll();

    if (overdueTasks.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (var task in overdueTasks) {
          task.isPostponed = true;
          await _isar.tasks.put(task);
        }
      });
    }
  }
}
