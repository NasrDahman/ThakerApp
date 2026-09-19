import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/lecture.dart';
import '../../data/services/study_repository.dart';
import '../../data/services/db_service.dart';
import 'package:isar/isar.dart';

class ScheduleView extends ConsumerStatefulWidget {
  const ScheduleView({super.key});

  @override
  ConsumerState<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<ScheduleView> {
  int _selectedDay = 7;
  int _maxLectures = 4;
  final TextEditingController _maxCtrl = TextEditingController(text: '4');
  final List<TextEditingController> _lectureControllers = [];

  final List<Map<String, dynamic>> _days = const [
    {'name': 'السبت', 'val': 6},
    {'name': 'الأحد', 'val': 7},
    {'name': 'الإثنين', 'val': 1},
    {'name': 'الثلاثاء', 'val': 2},
    {'name': 'الأربعاء', 'val': 3},
    {'name': 'الخميس', 'val': 4},
    {'name': 'الجمعة (المراجعة)', 'val': 5},
  ];

  @override
  void initState() {
    super.initState();
    _loadMaxLectures();
  }

  Future<void> _loadMaxLectures() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMax = prefs.getInt('max_lectures') ?? 4;
    setState(() {
      _maxLectures = savedMax;
      _maxCtrl.text = '$savedMax';
    });
    _initInputs();
    _loadCurrentDayLectures();
  }

  void _initInputs() {
    _lectureControllers.clear();
    for (int i = 0; i < _maxLectures; i++) {
      _lectureControllers.add(TextEditingController());
    }
  }

  Future<void> _loadCurrentDayLectures() async {
    final repo = ref.read(studyRepoProvider);
    final lectures = await repo.getLecturesByDay(_selectedDay);
    for (int i = 0; i < _maxLectures; i++) {
      final match = lectures.where((l) => l.slotIndex == (i + 1));
      if (match.isNotEmpty) {
        _lectureControllers[i].text = match.first.subjectName;
      } else {
        _lectureControllers[i].clear();
      }
    }
    setState(() {});
  }

  Future<void> _saveCurrentDayLectures() async {
    final isar = DBService.isar;
    await isar.writeTxn(() async {
      final old = await isar.lectures.filter().dayOfWeekEqualTo(_selectedDay).findAll();
      for (var l in old) {
        await isar.lectures.delete(l.id);
      }
      for (int i = 0; i < _maxLectures; i++) {
        final text = _lectureControllers[i].text.trim();
        if (text.isNotEmpty) {
          final lec = Lecture()
            ..dayOfWeek = _selectedDay
            ..slotIndex = i + 1
            ..subjectName = text;
          await isar.lectures.put(lec);
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ جدول هذا اليوم بنجاح')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayName = _days.firstWhere((d) => d['val'] == _selectedDay)['name'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدولي الأسبوعي'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('الحد الأقصى للمحاضرات: ', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final val = int.tryParse(_maxCtrl.text.trim()) ?? 4;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('max_lectures', val);
                      setState(() {
                        _maxLectures = val;
                        _initInputs();
                      });
                      _loadCurrentDayLectures();
                    },
                    child: const Text('تحديث'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // الجدول المقسم لأعمدة حسب عدد المحاضرات
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الجدول الأسبوعي الشامل',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Lecture>>(
                    future: DBService.isar.lectures.where().findAll(),
                    builder: (context, snapshot) {
                      final allLecs = snapshot.data ?? [];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
                          columnWidths: {
                            0: const FixedColumnWidth(85),
                            for (int i = 1; i <= _maxLectures; i++)
                              i: const FixedColumnWidth(100),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.12)),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Text('اليوم', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                for (int i = 1; i <= _maxLectures; i++)
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text('محاضرة $i', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                              ],
                            ),
                            ..._days.map((d) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(d['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  for (int i = 1; i <= _maxLectures; i++)
                                    Builder(builder: (context) {
                                      final match = allLecs.where((l) => l.dayOfWeek == d['val'] && l.slotIndex == i);
                                      final subject = match.isNotEmpty ? match.first.subjectName : '—';
                                      return Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          subject,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 11, color: subject == '—' ? Colors.grey : null),
                                        ),
                                      );
                                    }),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.map((d) {
                final isSelected = _selectedDay == d['val'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(d['name'], style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDay = d['val']);
                        _loadCurrentDayLectures();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تعديل محاضرات يوم: $selectedDayName',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  ...List.generate(_maxLectures, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 75,
                            child: Text('محاضرة ${index + 1}:', style: const TextStyle(fontSize: 12)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _lectureControllers[index],
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                hintText: 'اسم المقرر...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCurrentDayLectures,
                      child: Text('حفظ جدول يوم $selectedDayName'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
