import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_controller.dart';
import '../widgets/action_tile.dart';
import '../widgets/feature_header.dart';

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _language = 'English';
  double _quranFontSize = 18;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _quranFontSize = prefs.getDouble('quran_font_size') ?? 18;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setString('language', _language);
    await prefs.setDouble('quran_font_size', _quranFontSize);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FeatureHeader(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Appearance, language & reading preferences',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                ThemeController.setDarkMode(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: _language,
            onTap: () => showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Select Language'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      ['English', 'Arabic', 'Urdu', 'Indonesian', 'Turkish']
                          .map((lang) => RadioMenuButton<String>(
                                value: lang,
                                groupValue: _language,
                                onChanged: (value) {
                                  setState(() => _language = value!);
                                  Navigator.pop(context);
                                },
                                child: Text(lang),
                              ))
                          .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quran font size', style: theme.textTheme.titleMedium),
                Text('${_quranFontSize.toInt()}', style: theme.textTheme.bodySmall),
                Slider(
                  value: _quranFontSize,
                  min: 14,
                  max: 30,
                  divisions: 8,
                  onChanged: (value) =>
                      setState(() => _quranFontSize = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.info_rounded,
            title: 'About',
            subtitle: 'Rafiq — Your Islamic Companion v1.0.0',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Rafiq',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.mosque, size: 48),
              children: const [
                Text(
                    'A comprehensive Islamic app with Quran, prayer times, and spiritual tools.')
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}
