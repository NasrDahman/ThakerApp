import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lecture.dart';
import '../../data/services/study_repository.dart';

class ScheduleView extends ConsumerStatefulWidget {
  const ScheduleView({super.key});

  @override
  ConsumerState<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<ScheduleView> {
  int _selectedDay = DateTime.now().weekday;

  final List<Map<String, dynamic>> _days = const [
    {'name': 'السبت', 'val': 6},
    {'name': 'الأحد', 'val': 7},
    {'name': 'الاثنين', 'val': 1},
    {'name': 'الثلاثاء', 'val': 2},
    {'name': 'الأربعاء', 'val': 3},
    {'name': 'الخميس', 'val': 4},
  ];

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(studyRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدولي الأسبوعي'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _days.map((d) {
                final isSelected = _selectedDay == d['val'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(d['name']),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDay = d['val']);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Lecture>>(
              future: repo.getLecturesByDay(_selectedDay),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final lectures = snapshot.data!;
                if (lectures.isEmpty) {
                  return const Center(
                    child: Text('لا توجد محاضرات مضافة لهذا اليوم'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    final item = lectures[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${item.slotIndex}'),
                        ),
                        title: Text(item.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.room != null && item.room!.isNotEmpty 
                            ? 'القاعة: ${item.room}' 
                            : 'لم تحدد القاعة'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            await repo.deleteLecture(item.id);
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLectureDialog(context),
        label: const Text('إضافة محاضرة'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLectureDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final slotCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مقرر دراسي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'اسم المقرر'),
            ),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(labelText: 'المكان / القاعة (اختياري)'),
            ),
            TextField(
              controller: slotCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ترتيب المحاضرة (1, 2, 3...)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectCtrl.text.trim().isNotEmpty) {
                final lecture = Lecture()
                  ..subjectName = subjectCtrl.text.trim()
                  ..room = roomCtrl.text.trim()
                  ..dayOfWeek = _selectedDay
                  ..slotIndex = int.tryParse(slotCtrl.text.trim()) ?? 1;

                await ref.read(studyRepoProvider).saveLecture(lecture);
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
