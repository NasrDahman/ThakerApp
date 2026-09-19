import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTime();
  }

  Future<void> _loadSavedTime() async {
    final time = await NotificationService.getReportTime();
    if (mounted) {
      setState(() {
        _selectedTime = time;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      await NotificationService.saveReportTime(picked.hour, picked.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم ضبط وقت التقرير اليومي بنجاح')),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'صباحاً' : 'مساءً';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'التنبيهات والتقارير',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded),
                        title: const Text('وقت التقرير اليومي'),
                        subtitle: Text('المحدد حالياً: ${_formatTime(_selectedTime)}'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _pickTime,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('تجربة إشعار التقرير الآن'),
                        subtitle: const Text('إرسال تقرير تجريبي لشريط الإشعارات فوراً'),
                        trailing: const Icon(Icons.send_rounded, size: 18),
                        onTap: () async {
                          await NotificationService.showDailyReportNotification();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إرسال الإشعار التجريبي')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'حول التطبيق',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: const ListTile(
                    leading: Icon(Icons.person_outline_rounded),
                    title: Text('المطور'),
                    subtitle: Text('نصرالله دهمان'),
                  ),
                ),
              ],
            ),
    );
  }
}
