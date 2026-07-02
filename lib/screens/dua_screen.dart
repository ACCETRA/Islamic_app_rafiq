import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

// ==================== DUA SCREEN ====================
class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  final List<String> _categories = [
    'Morning & Evening',
    'Daily Life',
    'Travel',
    'Health & Healing',
    'Family & Children',
    'Protection',
    'Forgiveness',
    'Quranic Duas',
    'Ramadan',
    'Hajj',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Duas & Supplications')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily supplications',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Make du’a part of your routine',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                DuaCategoryScreen(category: _categories[index]),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 280),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _categories[index],
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _categories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.15,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DuaCategoryScreen extends StatelessWidget {
  final String category;

  const DuaCategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final duas = getDuasForCategory(category);

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: duas.length,
        itemBuilder: (BuildContext context, index) {
          final dua = duas[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dua['arabic'] ?? '',
                    style: AppTheme.arabic(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(dua['translation'] ?? '',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(dua['reference'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 20),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () {
                          final text =
                              '${dua['arabic'] ?? ''}\n\n${dua['translation'] ?? ''}';
                          SharePlus.instance.share(ShareParams(text: text));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, String>> getDuasForCategory(String category) {
    const allDuas = {
      'Morning & Evening': [
        {
          'arabic': 'أَصْـبَحْنا وَأَصْـبَحَ المُلْكُ للهِ وَالحَمْدُ للهِ',
          'translation':
              'We have reached the morning and all sovereignty belongs to Allah.',
          'reference': 'Sahih Muslim 4/2088'
        },
      ],
      'Daily Life': [
        {
          'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          'translation': 'In the name of Allah, the Entirely Merciful.',
          'reference': 'Sahih Bukhari'
        },
      ],
    };
    return allDuas[category] ?? [];
  }
}

