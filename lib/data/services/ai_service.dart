import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/chat_message.dart';
import 'db_service.dart';

final chatMessagesProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  return DBService.isar.chatMessages.where().sortByTimestamp().watch(fireImmediately: true);
});

final aiServiceProvider = Provider((ref) => AIService());

class AIService {
  // بوابة وسيطة مفتوحة لتجاوز حجب نطاق workers.dev محلياً
  static const String workerEndpoint = 'https://api.allorigins.win/raw?url=https://thaker-ai-proxy.26160184.workers.dev';

  Future<void> askAssistant(String prompt) async {
    final userMsg = ChatMessage()
      ..text = prompt
      ..isUser = true
      ..timestamp = DateTime.now();

    await DBService.isar.writeTxn(() async {
      await DBService.isar.chatMessages.put(userMsg);
    });

    try {
      final response = await http.post(
        Uri.parse(workerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['reply'] != null) {
        final replyText = data['reply'] as String;
        final aiMsg = ChatMessage()
          ..text = replyText
          ..isUser = false
          ..timestamp = DateTime.now();

        await DBService.isar.writeTxn(() async {
          await DBService.isar.chatMessages.put(aiMsg);
        });
      } else {
        throw Exception(data['error'] ?? 'فشل الاتصال بالخادم');
      }
    } catch (e) {
      final errorMsg = ChatMessage()
        ..text = 'عذراً، حدث خطأ أثناء معالجة الطلب. تأكد من اتصال الإنترنت ثم أعد المحاولة.'
        ..isUser = false
        ..timestamp = DateTime.now();

      await DBService.isar.writeTxn(() async {
        await DBService.isar.chatMessages.put(errorMsg);
      });
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    await DBService.isar.writeTxn(() async {
      await DBService.isar.chatMessages.clear();
    });
  }
}
