import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/chat_message.dart';
import 'db_service.dart';

// ضع رابط العامل الخاص بك هنا
const String workerEndpoint = 'https://thaker-ai-proxy.26160184.workers.dev';

final aiServiceProvider = Provider((ref) => AIService());

final chatMessagesProvider = StreamProvider.autoDispose<List<ChatMessage>>((ref) {
  return DBService.isar.chatMessages
      .where()
      .sortByTimestampDesc()
      .watch(fireImmediately: true);
});

class AIService {
  final Isar _isar = DBService.isar;

  Future<void> askAssistant({
    required String prompt,
    required Function(String chunk) onChunkReceived,
  }) async {
    // 1. حفظ رسالة المستخدم في Isar
    final userMsg = ChatMessage()
      ..text = prompt
      ..isUser = true
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.chatMessages.put(userMsg);
    });

    // 2. إرسال الطلب للخادم الوسيط
    final request = http.Request('POST', Uri.parse(workerEndpoint));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'prompt': prompt,
      'systemPrompt': 'أنت المساعد الذكي لتطبيق ذاكر. أجب باحترافية وتلخيص يناسب الطلاب.',
    });

    final streamedResponse = await request.send();
    final buffer = StringBuffer();

    // 3. قراءة البيانات المتدفقة (Streaming SSE)
    await streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        try {
          final data = jsonDecode(jsonStr);
          final textChunk = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (textChunk != null) {
            buffer.write(textChunk);
            onChunkReceived(textChunk);
          }
        } catch (_) {}
      }
    }).asFuture();

    // 4. حفظ إجابة المساعد كاملة في Isar
    if (buffer.isNotEmpty) {
      final aiMsg = ChatMessage()
        ..text = buffer.toString()
        ..isUser = false
        ..timestamp = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(aiMsg);
      });
    }
  }

  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.chatMessages.clear();
    });
  }
}
