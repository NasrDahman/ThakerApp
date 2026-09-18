import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/ai_service.dart';

class AiView extends ConsumerStatefulWidget {
  const AiView({super.key});

  @override
  ConsumerState<AiView> createState() => _AiViewState();
}

class _AiViewState extends ConsumerState<AiView> {
  final _controller = TextEditingController();
  String _liveAiResponse = '';
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
      _liveAiResponse = '';
    });

    try {
      await ref.read(aiServiceProvider).askAssistant(
            prompt: text,
            onChunkReceived: (chunk) {
              setState(() {
                _liveAiResponse += chunk;
              });
            },
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الاتصال: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _liveAiResponse = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ذاكر AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'مسح الأرشيف',
            onPressed: () => ref.read(aiServiceProvider).clearHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: history.when(
              data: (messages) {
                return ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_isLoading && _liveAiResponse.isNotEmpty)
                      _buildChatBubble(_liveAiResponse, isUser: false, isLive: true),
                    ...messages.map((m) => _buildChatBubble(m.text, isUser: m.isUser)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),
          if (_isLoading && _liveAiResponse.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'اسأل عن أي مسألة دراسية...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isUser, bool isLive = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.indigo
              : (isLive ? Colors.indigo.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : null,
            fontStyle: isLive ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
