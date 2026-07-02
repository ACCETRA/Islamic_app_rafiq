import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await AuthService.init();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.mintTeal,
              child: const Icon(Icons.mosque_rounded,
                  size: 64, color: AppColors.deepNavy),
            ),
            const SizedBox(height: 24),
            Text(
              'Rafiq',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Islamic Companion',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.mintTeal,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
