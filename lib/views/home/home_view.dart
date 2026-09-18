import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/study_repository.dart';
import '../../data/models/task.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // تفعيل الترحيل التلقائي عند فتح الواجهة
    ref.read(studyRepoProvider).checkAndPostponeTasks();

    final todayLectures = ref.watch(todayLecturesProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final postponedTasks = ref.watch(postponedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ذاكر - جدول اليوم'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. قسم محاضرات اليوم
          const Text('محاضرات اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          todayLectures.when(
            data: (lectures) {
              if (lectures.isEmpty) {
                return _buildEmptyBox('لا توجد محاضرات مجدولة لهذا اليوم');
              }
              return Column(
                children: lectures.map((lec) => Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: Text('${lec.slotIndex}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(lec.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(lec.room != null && lec.room!.isNotEmpty ? 'القاعة: ${lec.room}' : 'دون قاعة'),
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ: $e'),
          ),

          const SizedBox(height: 24),

          // 2. قسم مهام اليوم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مهام اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.indigo),
                onPressed: () => _showAddTaskDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 8),
          todayTasks.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return _buildEmptyBox('لا توجد مهام حالية. اضغط + لإضافة مهمة');
              }
              return Column(
                children: tasks.map((t) => _buildTaskItem(context, ref, t)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ: $e'),
          ),

          const SizedBox(height: 24),

          // 3. قسم المهام المؤجلة
          postponedTasks.when(
            data: (tasks) {
              if (tasks.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المهام المؤجلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  ...tasks.map((t) => _buildTaskItem(context, ref, t, isPostponed: true)),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Task task, {bool isPostponed = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) {
            ref.read(studyRepoProvider).toggleTaskStatus(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
          onPressed: () {
            ref.read(studyRepoProvider).deleteTask(task.id);
          },
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مهمة جديدة'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'اكتب المهمة هنا...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref.read(studyRepoProvider).addTask(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
