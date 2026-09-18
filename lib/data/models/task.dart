import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime createdAt;
  bool isCompleted = false;
  bool isPostponed = false; // هل تم ترحيلها إلى قائمة المؤجلات

  int? linkedLectureId; // ربط المهمة بمحاضرة اختيارياً
}
