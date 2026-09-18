import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/db_service.dart';
import 'data/services/theme_service.dart';
import 'data/services/notification_service.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: ThakerApp()));
}

class ThakerApp extends ConsumerWidget {
  const ThakerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ذاكر',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.indigo,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: MainNavigationScreen(),
      ),
    );
  }
}
