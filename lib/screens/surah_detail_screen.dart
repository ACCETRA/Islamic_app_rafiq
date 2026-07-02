import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../theme/app_theme.dart';

// ==================== SURAH DETAIL SCREEN ====================
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String translationCode;
  final Function(int, int)? onPlayAudio;
  final Function(String)? onPlayTTS;
  final Function(int, int, String, String)? onBookmark;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.translationCode = 'en.sahih',
    this.onPlayAudio,
    this.onPlayTTS,
    this.onBookmark,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool showTranslation = true;
  bool showTafsir = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahNameEnglish(widget.surahNumber)),
        actions: [
          IconButton(
            icon:
                Icon(showTranslation ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => showTranslation = !showTranslation),
          ),
          IconButton(
            icon: Icon(showTafsir ? Icons.book : Icons.book_outlined),
            onPressed: () => setState(() => showTafsir = !showTafsir),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: quran.getVerseCount(widget.surahNumber),
        itemBuilder: (BuildContext context, index) {
          final ayahNumber = index + 1;
          final arabicText = quran.getVerse(widget.surahNumber, ayahNumber);
          final translation =
              quran.getVerseTranslation(widget.surahNumber, ayahNumber);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        child: Text('$ayahNumber',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () => widget.onPlayAudio
                                ?.call(widget.surahNumber, ayahNumber),
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic),
                            onPressed: () => widget.onPlayTTS?.call(arabicText),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            onPressed: () => widget.onBookmark?.call(
                              widget.surahNumber,
                              ayahNumber,
                              quran.getSurahNameEnglish(widget.surahNumber),
                              arabicText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    arabicText,
                    style: AppTheme.arabic(fontSize: 22),
                  ),
                  if (showTranslation) ...[
                    const SizedBox(height: 12),
                    Text(translation, style: const TextStyle(fontSize: 16)),
                  ],
                  if (showTafsir) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tafsir commentary would be displayed here',
                        style: TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

