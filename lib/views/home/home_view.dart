import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard(
            context,
            title: 'محاضرات اليوم',
            subtitle: 'لا توجد محاضرات مضافة لهذا اليوم بعد',
            icon: Icons.school_outlined,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'مهام اليوم',
            subtitle: 'جميع المهام مكتملة، أو لم تقم بإضافة مهام جديدة',
            icon: Icons.checklist_rtl_rounded,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            title: 'المهام المؤجلة',
            subtitle: 'لا توجد أي مهام مرحلة من الأيام السابقة',
            icon: Icons.history_rounded,
            color: Colors.amber[800]!,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
