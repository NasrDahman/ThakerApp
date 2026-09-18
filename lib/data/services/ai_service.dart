import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'db_service.dart';

class AIService {
  static const String workerEndpoint = 'https://thaker-ai-proxy.26160184.workers.dev';

  static Future<String> sendMessage(String userPrompt) async {
    // 1. حفظ رسالة المستخدم محلياً
    final userMsg = ChatMessage()
      ..text = userPrompt
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
          'prompt': userPrompt,
          'systemPrompt': 'أنت ذاكر، مرشد ومساعد دراسي ذكي للطلاب. إجاباتك دقيقة، مركزة، وداعمة باللغة العربية.',
        }),
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['reply'] != null) {
        final replyText = data['reply'] as String;

        // 2. حفظ رد الذكاء الاصطناعي محلياً
        final aiMsg = ChatMessage()
          ..text = replyText
          ..isUser = false
          ..timestamp = DateTime.now();

        await DBService.isar.writeTxn(() async {
          await DBService.isar.chatMessages.put(aiMsg);
        });

        return replyText;
      } else {
        final errorMsg = data['error'] ?? 'حدث خطأ غير متوقع من الخادم';
        throw Exception(errorMsg);
      }
    } catch (e) {
      rethrow;
    }
  }
}
