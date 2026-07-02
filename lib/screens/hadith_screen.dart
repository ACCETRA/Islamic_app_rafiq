import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/hadith_api_service.dart';

// ==================== HADITH SCREEN ====================
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  String _selectedCollection = 'bukhari';
  final List<String> _collections = [
    'bukhari',
    'muslim',
    'abudawud',
    'tirmidhi',
    'nasai',
    'ibnmajah'
  ];

  List<Hadith> _hadiths = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final hadiths = await HadithApiService.getHadiths(_selectedCollection);
      setState(() => _hadiths = hadiths);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHadiths,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hadith collection',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedCollection.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _collections.map((collection) {
                      final selected = collection == _selectedCollection;
                      return ChoiceChip(
                        label: Text(collection.toUpperCase()),
                        selected: selected,
                        onSelected: (value) {
                          if (value) {
                            setState(() => _selectedCollection = collection);
                            _loadHadiths();
                          }
                        },
                        selectedColor: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimary.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.10),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final hadith = _hadiths[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  hadith.hadithNumber,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hadith.chapterTitle,
                                style: theme.textTheme.titleMedium,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded),
                              onPressed: () {
                                final text = '${hadith.text}\n\nSource: ${_selectedCollection.toUpperCase()} #${hadith.hadithNumber}';
                                SharePlus.instance.share(ShareParams(text: text));
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hadith.text,
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                        ),
                        if (hadith.grades.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            hadith.grades.join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: _hadiths.length,
            ),
          ),
        ),
      ],
    );
  }

}
