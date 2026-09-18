import 'package:isar/isar.dart';

part 'lecture.g.dart';

@collection
class Lecture {
  Id id = Isar.autoIncrement;

  late String subjectName;
  String? room;
  late int dayOfWeek; // 1 = الاثنين ... 7 = الأحد (وفق نظام DateTime)
  late int slotIndex; // ترتيب المحاضرة في اليوم (1، 2، 3...)
  int colorHex = 0xFF2196F3; // لون افتراضي (أزرق)
}
