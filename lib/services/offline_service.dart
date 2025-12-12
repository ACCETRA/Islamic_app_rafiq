import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;

class OfflineService {
  static const String _downloadedSurahsKey = 'downloaded_surahs';

  static Future<Directory> get _cacheDir async {
    final dir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${dir.path}/quran_offline');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }
    return quranDir;
  }

  // Check if offline mode is available
  static Future<bool> isOfflineAvailable() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_downloadedSurahsKey) ?? [];
    return downloaded.isNotEmpty;
  }

  // Get list of downloaded surahs
  static Future<Set<int>> getDownloadedSurahs() async {
    if (kIsWeb) return {};
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_downloadedSurahsKey) ?? [];
    return downloaded.map((s) => int.parse(s)).toSet();
  }

  // Download a surah for offline use
  static Future<bool> downloadSurah(int surahNumber,
      {Function(double)? onProgress}) async {
    if (kIsWeb) return false;

    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/surah_$surahNumber.json');

      // Get surah data
      final verseCount = quran.getVerseCount(surahNumber);
      final verses = <Map<String, dynamic>>[];

      for (int i = 1; i <= verseCount; i++) {
        verses.add({
          'verse': i,
          'arabic': quran.getVerse(surahNumber, i),
          'translation': quran.getVerseTranslation(surahNumber, i),
        });
        onProgress?.call(i / verseCount);
      }

      final surahData = {
        'number': surahNumber,
        'name': quran.getSurahName(surahNumber),
        'nameArabic': quran.getSurahNameArabic(surahNumber),
        'verseCount': verseCount,
        'verses': verses,
        'downloadedAt': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(surahData));

      // Update downloaded list
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_downloadedSurahsKey) ?? [];
      if (!downloaded.contains(surahNumber.toString())) {
        downloaded.add(surahNumber.toString());
        await prefs.setStringList(_downloadedSurahsKey, downloaded);
      }

      return true;
    } catch (e) {
      debugPrint('Error downloading surah: $e');
      return false;
    }
  }

  // Download entire Quran
  static Future<void> downloadAllSurahs(
      {Function(int, int)? onProgress}) async {
    if (kIsWeb) return;

    for (int i = 1; i <= 114; i++) {
      await downloadSurah(i);
      onProgress?.call(i, 114);
    }
  }

  // Get offline surah data
  static Future<Map<String, dynamic>?> getSurahOffline(int surahNumber) async {
    if (kIsWeb) return null;

    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/surah_$surahNumber.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return json.decode(content);
      }
      return null;
    } catch (e) {
      debugPrint('Error reading offline surah: $e');
      return null;
    }
  }

  // Check if surah is downloaded
  static Future<bool> isSurahDownloaded(int surahNumber) async {
    if (kIsWeb) return false;
    final downloaded = await getDownloadedSurahs();
    return downloaded.contains(surahNumber);
  }

  // Delete offline surah
  static Future<void> deleteSurah(int surahNumber) async {
    if (kIsWeb) return;

    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/surah_$surahNumber.json');

      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_downloadedSurahsKey) ?? [];
      downloaded.remove(surahNumber.toString());
      await prefs.setStringList(_downloadedSurahsKey, downloaded);
    } catch (e) {
      debugPrint('Error deleting offline surah: $e');
    }
  }

  // Delete all offline data
  static Future<void> clearAllOfflineData() async {
    if (kIsWeb) return;

    try {
      final dir = await _cacheDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadedSurahsKey);
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }

  // Get total offline storage size
  static Future<int> getStorageSize() async {
    if (kIsWeb) return 0;

    try {
      final dir = await _cacheDir;
      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
