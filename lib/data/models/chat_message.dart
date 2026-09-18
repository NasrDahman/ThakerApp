import 'package:isar/isar.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  late String text;
  late bool isUser; // true إذا كان الطالب، false إذا كان الرد من AI
  late DateTime timestamp;
  String? sessionId; // لتجميع المحادثات في جلسات/مواضيع منفصلة
}
