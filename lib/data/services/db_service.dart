import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/lecture.dart';
import '../models/task.dart';
import '../models/chat_message.dart';

class DBService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [LectureSchema, TaskSchema, ChatMessageSchema],
      directory: dir.path,
    );
  }
}
