import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../widgets/feature_header.dart';
import '../widgets/metric_card.dart';

// ==================== FASTING TRACKER ====================
class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _fastingDays = [];

  @override
  void initState() {
    super.initState();
    _loadFastingDays();
  }

  Future<void> _loadFastingDays() async {
    final days = await DatabaseHelper.instance
        .getFastingDays(_selectedDate.month, _selectedDate.year);
    setState(() => _fastingDays = days);
  }

  Future<void> _toggleFastingDay(DateTime date, String type) async {
    await DatabaseHelper.instance.saveFastingDay(date.toIso8601String(), type);
    _loadFastingDays();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fasting Tracker')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                const FeatureHeader(
                  icon: Icons.fastfood_rounded,
                  title: 'Fasting Tracker',
                  subtitle: 'Tap a day to mark it as fasted',
                ),
                const SizedBox(height: 14),
                MetricCard(
                  label: 'Days fasted in ${DateFormat('MMMM').format(_selectedDate)}',
                  value: '${_fastingDays.length}',
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Change'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                            _loadFastingDays();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              padding: const EdgeInsets.all(16),
              children: List.generate(
                  DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day,
                  (index) {
                final day = index + 1;
                final date =
                    DateTime(_selectedDate.year, _selectedDate.month, day);
                final isFasting = _fastingDays
                    .any((d) => d['date'] == date.toIso8601String());

                return GestureDetector(
                  onTap: () => _toggleFastingDay(date, 'voluntary'),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isFasting
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFasting
                            ? Colors.transparent
                            : colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isFasting
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight:
                              isFasting ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
