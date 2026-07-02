import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../theme/app_theme.dart';

// ==================== AZKAR SCREEN ====================
class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  int _currentAzkarIndex = 0;
  int _count = 0;
  final int _targetCount = 33;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _incrementCount() {
    setState(() {
      _count++;
      if (_count > _targetCount) _count = 0;
    });
    _controller.forward().then((_) => _controller.reverse());
    if (_count == _targetCount) Vibration.vibrate(duration: 100);
  }

  void _resetCount() => setState(() => _count = 0);

  void _nextAzkar(int listLength) {
    if (_currentAzkarIndex < listLength - 1) {
      setState(() {
        _currentAzkarIndex++;
        _count = 0;
      });
    }
  }

  void _previousAzkar() {
    if (_currentAzkarIndex > 0) {
      setState(() {
        _currentAzkarIndex--;
        _count = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: azkarData.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Azkar & Duas'),
          bottom: TabBar(
            isScrollable: true,
            onTap: (_) => setState(() {
              _currentAzkarIndex = 0;
              _count = 0;
            }),
            tabs: azkarData.keys.map((key) => Tab(text: key)).toList(),
          ),
        ),
        body: TabBarView(
          children: azkarData.entries.map((entry) {
            final list = entry.value;
            final isPrayerTab = entry.key == 'Prayer';
            final index = _currentAzkarIndex.clamp(0, list.length - 1);

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DhikrCard(
                          arabic: list[index]['arabic'] ?? '',
                          translation: list[index]['translation'] ?? '',
                        ),
                        const SizedBox(height: 14),
                        _PagerRow(
                          position: index + 1,
                          total: list.length,
                          onPrevious: _previousAzkar,
                          onNext: () => _nextAzkar(list.length),
                        ),
                        if (isPrayerTab) ...[
                          const SizedBox(height: 20),
                          _TasbihPanel(
                            count: _count,
                            target: _targetCount,
                            scaleAnimation: _scaleAnimation,
                            onTap: _incrementCount,
                            onReset: _resetCount,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({required this.arabic, required this.translation});

  final String arabic;
  final String translation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabic,
            style: AppTheme.arabic(fontSize: 24, color: colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            translation,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PagerRow extends StatelessWidget {
  const _PagerRow({
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int position;
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          onPressed: position > 1 ? onPrevious : null,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        Text(
          '$position / $total',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        IconButton.filledTonal(
          onPressed: position < total ? onNext : null,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}

class _TasbihPanel extends StatelessWidget {
  const _TasbihPanel({
    required this.count,
    required this.target,
    required this.scaleAnimation,
    required this.onTap,
    required this.onReset,
  });

  final int count;
  final int target;
  final Animation<double> scaleAnimation;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: scaleAnimation.value,
              child: child,
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tasbih counter', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Target $target · tap the circle to count',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
          ),
        ],
      ),
    );
  }
}

// ==================== AZKAR DATA ====================
final Map<String, List<Map<String, String>>> azkarData = {
  'Morning': [
    {
      'arabic': 'أَصْـبَحْنا وَأَصْـبَحَ المُلْكُ للهِ',
      'translation':
          'We have reached the morning and all sovereignty belongs to Allah.'
    },
    {
      'arabic': 'اللّهُـمَّ بِكَ أَصْبَحْـنا',
      'translation': 'O Allah, by You we enter the morning.'
    },
    {
      'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
      'translation': 'I seek refuge in the perfect words of Allah.'
    },
    {
      'arabic': 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      'translation': 'Allah is sufficient for me, there is no deity except Him.'
    },
    {
      'arabic': 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ',
      'translation': 'In the name of Allah with whose name nothing harms.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ',
      'translation': 'O Allah, I seek the best from You.'
    },
    {
      'arabic': 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ',
      'translation': 'O Allah, You are my Lord, there is no deity except You.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا',
      'translation': 'O Allah, I ask You for beneficial knowledge.'
    },
    {
      'arabic': 'اللَّهُمَّ عَافِنِي فِي بَدَنِي',
      'translation': 'O Allah, grant me health in my body.'
    },
    {
      'arabic': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      'translation': 'Glory be to Allah and praise is due to Him.'
    },
  ],
  'Evening': [
    {
      'arabic': 'أَمْسَيْنا وَأَمْسَى المُلْكُ للهِ',
      'translation':
          'We have reached the evening and all sovereignty belongs to Allah.'
    },
    {
      'arabic': 'اللّهُـمَّ بِكَ أَمْسَـينا',
      'translation': 'O Allah, by You we enter the evening.'
    },
    {
      'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
      'translation': 'I seek refuge in the perfect words of Allah.'
    },
    {
      'arabic': 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      'translation': 'Allah is sufficient for me, there is no deity except Him.'
    },
    {
      'arabic': 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ',
      'translation': 'In the name of Allah with whose name nothing harms.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ',
      'translation': 'O Allah, I seek the best from You.'
    },
  ],
  'Prayer': [
    {'arabic': 'سُبْحَانَ اللَّهِ', 'translation': 'Glory be to Allah.'},
    {
      'arabic': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      'translation': 'Glory be to Allah and praise is due to Him.'
    },
    {
      'arabic': 'سُبْحَانَ اللَّهِ الْعَظِيمِ',
      'translation': 'Glory be to Allah, the Almighty.'
    },
  ],
};
