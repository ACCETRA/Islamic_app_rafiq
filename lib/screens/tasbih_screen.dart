import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

// ==================== TASBIH SCREEN ====================
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  final int _targetCount = 33;
  int _totalCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final List<String> _tasbihTypes = [
    'Subhanallah',
    'Alhamdulillah',
    'Allahu Akbar',
    'La ilaha illallah'
  ];
  int _currentTasbihType = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalCount = prefs.getInt('tasbih_total') ?? 0);
  }

  Future<void> _saveTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_total', _totalCount);
  }

  void _incrementCount() {
    setState(() {
      _count++;
      _totalCount++;
      if (_count > _targetCount) _count = 1;
    });
    _controller.forward().then((_) => _controller.reverse());
    if (_count == _targetCount) Vibration.vibrate(duration: 100);
    _saveTotalCount();
  }

  void _resetCount() => setState(() => _count = 0);

  void _nextTasbihType() {
    setState(() {
      _currentTasbihType = (_currentTasbihType + 1) % _tasbihTypes.length;
      _count = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih Counter')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today’s total',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_totalCount',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _tasbihTypes[_currentTasbihType],
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tasbihTypes[_currentTasbihType],
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (BuildContext context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: GestureDetector(
                              onTap: _incrementCount,
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.22),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$_count / $_targetCount',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton.icon(
                            onPressed: _nextTasbihType,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('Next'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _resetCount,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
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

