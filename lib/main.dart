import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_helper.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip database initialization on web platform
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }
  await ThemeController.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Islamic Companion',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
