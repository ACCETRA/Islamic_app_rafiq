import 'package:flutter/material.dart';
import '../widgets/action_tile.dart';
import '../widgets/feature_header.dart';
import 'calendar_screen.dart';
import 'dua_screen.dart';
import 'fasting_tracker_screen.dart';
import 'hadith_screen.dart';
import 'settings_screen.dart';
import 'zakat_calculator_screen.dart';

/// Dashboard for the secondary features that don't fit in the primary
/// 5-tab shell. Each row opens its screen only when tapped, so none of
/// their `initState` side effects run until the user asks for them.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        icon: Icons.calendar_month_rounded,
        title: 'Islamic Calendar',
        subtitle: 'Hijri dates & events',
        builder: (_) => const CalendarScreen(),
      ),
      _MoreItem(
        icon: Icons.format_quote_rounded,
        title: 'Hadith',
        subtitle: 'Sayings of the Prophet ﷺ',
        builder: (_) => const HadithScreen(),
      ),
      _MoreItem(
        icon: Icons.volunteer_activism_rounded,
        title: 'Duas',
        subtitle: 'Supplications for daily life',
        builder: (_) => const DuaScreen(),
      ),
      _MoreItem(
        icon: Icons.fastfood_rounded,
        title: 'Fasting Tracker',
        subtitle: 'Track your fasting days',
        builder: (_) => const FastingTrackerScreen(),
      ),
      _MoreItem(
        icon: Icons.calculate_rounded,
        title: 'Zakat Calculator',
        subtitle: 'Work out what you owe',
        builder: (_) => const ZakatCalculatorScreen(),
      ),
      _MoreItem(
        icon: Icons.settings_rounded,
        title: 'Settings',
        subtitle: 'Appearance, language & more',
        builder: (_) => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const FeatureHeader(
            icon: Icons.apps_rounded,
            title: 'More tools',
            subtitle: 'Everything else Rafiq has to offer',
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            ActionTile(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: item.builder),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}
