import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/theme_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const Text('التنبيهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded),
              title: const Text('وقت التقرير اليومي'),
              subtitle: const Text('الافتراضي: 10:00 مساءً'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                // سنربطه بمحدد الوقت TimePicker
              },
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
