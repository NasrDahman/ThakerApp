import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/theme_service.dart';
import '../../data/services/notification_service.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  String _reportTimeText = '10:00 مساءً';

  @override
  void initState() {
    super.initState();
    _loadSavedTime();
  }

  Future<void> _loadSavedTime() async {
    final time = await NotificationService.getReportTime();
    final hour = time['hour']!;
    final minute = time['minute']!.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'مساءً' : 'صباحاً';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    setState(() {
      _reportTimeText = '$displayHour:$minute $period';
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
    );

    if (picked != null) {
      await NotificationService.saveReportTime(picked.hour, picked.minute);
      _loadSavedTime();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث وقت الإشعار اليومي بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('المظهر والعرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.brightness_6_rounded),
              title: const Text('الوضع الداكن'),
              trailing: DropdownButton<ThemeMode>(
                value: currentTheme,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('النظام')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('فاتح')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('داكن')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref.read(themeNotifierProvider.notifier).setTheme(mode);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('التنبيهات والتقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: const Text('وقت التقرير اليومي'),
                  subtitle: Text('المحدد حالياً: $_reportTimeText'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _pickTime,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.send_to_mobile_rounded, color: Colors.indigo),
                  title: const Text('تجربة إشعار التقرير الآن'),
                  subtitle: const Text('إرسال تقرير تجريبي لشريط الإشعارات فوراً'),
                  onTap: () async {
                    await NotificationService.showDailyReportNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال إشعار التقرير')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('حول التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
