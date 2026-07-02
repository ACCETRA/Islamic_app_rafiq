import 'package:flutter/material.dart';
import '../widgets/adaptive_shell.dart';
import 'azkar_screen.dart';
import 'more_screen.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';
import 'quran_screen.dart';

// ==================== HOME SCREEN ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveShell(
      destinations: [
        ShellDestination(
          icon: Icons.menu_book_rounded,
          label: 'Quran',
          builder: _buildQuran,
        ),
        ShellDestination(
          icon: Icons.access_time_rounded,
          label: 'Prayer',
          builder: _buildPrayer,
        ),
        ShellDestination(
          icon: Icons.explore_rounded,
          label: 'Qibla',
          builder: _buildQibla,
        ),
        ShellDestination(
          icon: Icons.auto_awesome_rounded,
          label: 'Azkar',
          builder: _buildAzkar,
        ),
        ShellDestination(
          icon: Icons.more_horiz_rounded,
          label: 'More',
          builder: _buildMore,
        ),
      ],
    );
  }
}

Widget _buildQuran(BuildContext context) => const QuranScreen();
Widget _buildPrayer(BuildContext context) => const PrayerScreen();
Widget _buildQibla(BuildContext context) => const QiblaScreen();
Widget _buildAzkar(BuildContext context) => const AzkarScreen();
Widget _buildMore(BuildContext context) => const MoreScreen();
