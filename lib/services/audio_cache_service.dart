import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioCacheService {
  static const String _cachedAudioKey = 'cached_audio_files';

  static Future<Directory> get _audioDir async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/quran_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  // Get audio URL for a verse
  static String getAudioUrl(int surahNumber, int verseNumber,
      {String reciter = 'Alafasy'}) {
    // Format: https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3
    final verseKey = _getVerseKey(surahNumber, verseNumber);
    final reciterCode = _getReciterCode(reciter);
    return 'https://cdn.islamic.network/quran/audio/128/$reciterCode/$verseKey.mp3';
  }

  static int _getVerseKey(int surah, int verse) {
    // Calculate absolute verse number
    const verseCounts = [
      0,
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6
    ];

    int key = verse;
    for (int i = 1; i < surah; i++) {
      key += verseCounts[i];
    }
    return key;
  }

  static String _getReciterCode(String reciter) {
    switch (reciter.toLowerCase()) {
      case 'alafasy':
        return 'ar.alafasy';
      case 'husary':
        return 'ar.husary';
      case 'minshawi':
        return 'ar.minshawi';
      case 'abdulbasit':
        return 'ar.abdulbasitmurattal';
      default:
        return 'ar.alafasy';
    }
  }

  // Check if audio is cached
  static Future<bool> isAudioCached(int surahNumber, int verseNumber) async {
    if (kIsWeb) return false;

    try {
      final dir = await _audioDir;
      final file = File('${dir.path}/${surahNumber}_$verseNumber.mp3');
      return file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get cached audio path or download
  static Future<String?> getAudioPath(
    int surahNumber,
    int verseNumber, {
    String reciter = 'Alafasy',
    Function(double)? onProgress,
  }) async {
    if (kIsWeb) return null;

    try {
      final dir = await _audioDir;
      final file = File('${dir.path}/${surahNumber}_$verseNumber.mp3');

      if (await file.exists()) {
        return file.path;
      }

      // Download audio
      final url = getAudioUrl(surahNumber, verseNumber, reciter: reciter);
      return await downloadAudio(url, surahNumber, verseNumber,
          onProgress: onProgress);
    } catch (e) {
      debugPrint('Error getting audio: $e');
      return null;
    }
  }

  // Download audio file
  static Future<String?> downloadAudio(
    String url,
    int surahNumber,
    int verseNumber, {
    Function(double)? onProgress,
  }) async {
    if (kIsWeb) return null;

    try {
      final dir = await _audioDir;
      final file = File('${dir.path}/${surahNumber}_$verseNumber.mp3');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(receivedBytes / totalBytes);
        }
      }

      await sink.close();

      // Update cached files list
      await _addToCachedList(surahNumber, verseNumber);

      return file.path;
    } catch (e) {
      debugPrint('Error downloading audio: $e');
      return null;
    }
  }

  // Download all audio for a surah
  static Future<void> downloadSurahAudio(
    int surahNumber,
    int verseCount, {
    String reciter = 'Alafasy',
    Function(int, int)? onProgress,
  }) async {
    if (kIsWeb) return;

    for (int i = 1; i <= verseCount; i++) {
      await getAudioPath(surahNumber, i, reciter: reciter);
      onProgress?.call(i, verseCount);
    }
  }

  static Future<void> _addToCachedList(int surahNumber, int verseNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_cachedAudioKey) ?? [];
    final key = '${surahNumber}_$verseNumber';
    if (!cached.contains(key)) {
      cached.add(key);
      await prefs.setStringList(_cachedAudioKey, cached);
    }
  }

  // Get list of cached audio
  static Future<List<String>> getCachedAudioList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cachedAudioKey) ?? [];
  }

  // Delete cached audio for a surah
  static Future<void> deleteSurahAudio(int surahNumber) async {
    if (kIsWeb) return;

    try {
      final dir = await _audioDir;
      final files = await dir.list().toList();

      for (final entity in files) {
        if (entity is File && entity.path.contains('${surahNumber}_')) {
          await entity.delete();
        }
      }

      // Update cached list
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cachedAudioKey) ?? [];
      cached.removeWhere((key) => key.startsWith('${surahNumber}_'));
      await prefs.setStringList(_cachedAudioKey, cached);
    } catch (e) {
      debugPrint('Error deleting surah audio: $e');
    }
  }

  // Clear all cached audio
  static Future<void> clearAllAudio() async {
    if (kIsWeb) return;

    try {
      final dir = await _audioDir;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedAudioKey);
    } catch (e) {
      debugPrint('Error clearing audio cache: $e');
    }
  }

  // Get total audio cache size
  static Future<int> getCacheSize() async {
    if (kIsWeb) return 0;

    try {
      final dir = await _audioDir;
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
