import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

// ==================== CALENDAR SCREEN ====================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hijri = HijriCalendar.fromDate(_currentDate);
    final daysInMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentDate.year, _currentDate.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () => setState(() => _currentDate = DateTime.now()),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM y').format(_currentDate),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hijri.getLongMonthName()} ${hijri.hYear} AH',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.16),
                    ),
                  ),
                  child: GridView.count(
                    crossAxisCount: 7,
                    childAspectRatio: 0.92,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: List.generate(daysInMonth + firstWeekday, (index) {
                      if (index < firstWeekday) return const SizedBox();
                      final day = index - firstWeekday + 1;
                      final isToday = _currentDate.day == day &&
                          _currentDate.month == DateTime.now().month;
                      final date =
                          DateTime(_currentDate.year, _currentDate.month, day);
                      final hijriDay = HijriCalendar.fromDate(date);
                      return Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hijriDay.hDay.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isToday
                                      ? colorScheme.onPrimary.withValues(alpha: 0.72)
                                      : colorScheme.onSurface.withValues(alpha: 0.58),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

