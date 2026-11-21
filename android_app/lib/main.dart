import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'ui/navigation/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: TeddyAiApp(),
    ),
  );
}

class TeddyAiApp extends StatelessWidget {
  const TeddyAiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teddy AI - Indian F&O Options Analyzer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.cyan,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyan,
          secondary: AppColors.green,
          surface: AppColors.surface,
          background: AppColors.background,
          error: AppColors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
