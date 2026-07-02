import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:quran/quran.dart' as quran;
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import 'bookmark_screen.dart';
import 'surah_detail_screen.dart';

// ==================== QURAN SCREEN ====================
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final List<Map<String, dynamic>> _translations = [
    {'name': 'English', 'code': 'en.sahih'},
    {'name': 'Urdu', 'code': 'ur.maududi'},
    {'name': 'Indonesian', 'code': 'id.indonesian'},
  ];
  String _selectedTranslation = 'en.sahih';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _ttsAvailable = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.4);
    _ttsAvailable = true;
  }

  Future<void> _playAyahAudio(int surah, int ayah) async {
    try {
      final audioUrl = quran.getAudioURLByVerse(surah, ayah);
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio not available for this verse')),
        );
      }
    }
  }

  Future<void> _playAyahTTS(String text) async {
    if (!_ttsAvailable) return;
    await _tts.speak(text);
  }

  Future<void> _addBookmark(int surahNumber, int ayahNumber, String surahName,
      String ayahText) async {
    await DatabaseHelper.instance.addBookmark({
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
      'ayah_text': ayahText,
      'translation': _selectedTranslation,
      'added_date': DateTime.now().toIso8601String(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bookmark added')));
    }
  }

  void _pushWithFade(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              showSearch(context: context, delegate: QuranSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            onPressed: () => _pushWithFade(const BookmarkScreen()),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedTranslation = value),
            itemBuilder: (context) => _translations
                .map((t) => PopupMenuItem<String>(
                      value: t['code'] as String,
                      child: Text(t['name'] as String),
                    ))
                .toList(),
            child: const Icon(Icons.translate_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today’s reading',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Al-Fatihah',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Begin your day with guidance and peace.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _pushWithFade(
                        SurahDetailScreen(
                          surahNumber: 1,
                          translationCode: _selectedTranslation,
                          onPlayAudio: _playAyahAudio,
                          onPlayTTS: _playAyahTTS,
                          onBookmark: _addBookmark,
                        ),
                      ),
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _quickActionCard(
                    icon: Icons.menu_book_rounded,
                    label: 'Continue',
                    onTap: () => _pushWithFade(
                      SurahDetailScreen(
                        surahNumber: 1,
                        translationCode: _selectedTranslation,
                        onPlayAudio: _playAyahAudio,
                        onPlayTTS: _playAyahTTS,
                        onBookmark: _addBookmark,
                      ),
                    ),
                  ),
                  _quickActionCard(
                    icon: Icons.bookmark_rounded,
                    label: 'Bookmarks',
                    onTap: () => _pushWithFade(const BookmarkScreen()),
                  ),
                  _quickActionCard(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onTap: () {
                      showSearch(context: context, delegate: QuranSearchDelegate());
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surahNumber = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _pushWithFade(
                          SurahDetailScreen(
                            surahNumber: surahNumber,
                            translationCode: _selectedTranslation,
                            onPlayAudio: _playAyahAudio,
                            onPlayTTS: _playAyahTTS,
                            onBookmark: _addBookmark,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    '$surahNumber',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quran.getSurahNameEnglish(surahNumber),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      quran.getSurahNameArabic(surahNumber),
                                      style: AppTheme.arabic(
                                        fontSize: 22,
                                        height: 1.2,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${quran.getVerseCount(surahNumber)} Ayahs',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: quran.totalSurahCount,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== QURAN SEARCH ====================
class QuranSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search for verses or surahs'));
    }

    final results = <Map<String, dynamic>>[];
    for (int s = 1; s <= quran.totalSurahCount; s++) {
      final surahName = quran.getSurahNameEnglish(s);
      if (surahName.toLowerCase().contains(query.toLowerCase())) {
        results.add({'type': 'surah', 'surah': s, 'name': surahName});
      }
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (BuildContext context, index) {
        final item = results[index];
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(item['name'] as String),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) =>
                    SurahDetailScreen(surahNumber: item['surah'] as int),
              ),
            );
          },
        );
      },
    );
  }
}

