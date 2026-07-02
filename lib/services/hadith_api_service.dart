import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Client for the free, open-source Hadith API by fawazahmed0
/// (https://github.com/fawazahmed0/hadith-api).
///
/// Data is served straight off the jsDelivr CDN — no API key,
/// account, or rate limit required. Since the dataset is static,
/// each collection is cached in memory for the session and on
/// disk across app launches, so it's only ever downloaded once.
class HadithApiService {
  static const String _baseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  static final Map<String, List<Hadith>> _memoryCache = {};
  static http.Client _client = http.Client();
  static bool _useDiskCache = true;

  static void setClientForTesting(http.Client client) {
    _client = client;
    _useDiskCache = false;
  }

  static void resetForTesting() {
    _memoryCache.clear();
    _client = http.Client();
    _useDiskCache = true;
  }

  /// [collection] is one of: bukhari, muslim, abudawud, tirmidhi, nasai, ibnmajah
  static Future<List<Hadith>> getHadiths(String collection) async {
    final cached = _memoryCache[collection];
    if (cached != null) return cached;

    if (_useDiskCache) {
      final diskRaw = await _readDiskCache(collection);
      if (diskRaw != null) {
        try {
          final hadiths = _parse(diskRaw);
          _memoryCache[collection] = hadiths;
          return hadiths;
        } catch (e) {
          debugPrint('Hadith cache for $collection is corrupted, refetching: $e');
        }
      }
    }

    final raw = await _fetchFromNetwork(collection);
    final hadiths = _parse(raw);
    _memoryCache[collection] = hadiths;
    if (_useDiskCache) {
      await _writeDiskCache(collection, raw);
    }
    return hadiths;
  }

  static Future<String> _fetchFromNetwork(String collection) async {
    final minifiedUri = Uri.parse('$_baseUrl/eng-$collection.min.json');
    final fallbackUri = Uri.parse('$_baseUrl/eng-$collection.json');
    final rawMinifiedUri = Uri.parse(
      'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/eng-$collection.min.json',
    );
    final rawFallbackUri = Uri.parse(
      'https://raw.githubusercontent.com/fawazahmed0/hadith-api/1/editions/eng-$collection.json',
    );

    final sources = [minifiedUri, fallbackUri, rawMinifiedUri, rawFallbackUri];

    for (final uri in sources) {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      }
    }

    throw HadithApiException(
      'Failed to load $collection from the available Hadith sources.',
    );
  }

  static Future<File?> _cacheFile(String collection) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/hadith_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/eng-$collection.json');
  }

  static Future<String?> _readDiskCache(String collection) async {
    try {
      final file = await _cacheFile(collection);
      if (file != null && await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Hadith cache read error: $e');
    }
    return null;
  }

  static Future<void> _writeDiskCache(String collection, String raw) async {
    try {
      final file = await _cacheFile(collection);
      await file?.writeAsString(raw);
    } catch (e) {
      debugPrint('Hadith cache write error: $e');
    }
  }

  static List<Hadith> _parse(String raw) {
    final body = json.decode(raw) as Map<String, dynamic>;
    final metadata = body['metadata'] as Map<String, dynamic>;
    final sections = (metadata['sections'] as Map).cast<String, dynamic>();
    final rawHadiths = (body['hadiths'] as List).cast<Map<String, dynamic>>();

    return rawHadiths.map((h) {
      final bookNumber = (h['reference'] as Map)['book'].toString();
      final grades = (h['grades'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((g) => '${g['name']}: ${g['grade']}')
              .toList() ??
          const <String>[];

      return Hadith(
        hadithNumber: _formatHadithNumber(h['hadithnumber']),
        text: h['text'] as String? ?? '',
        chapterTitle: sections[bookNumber] as String? ?? '',
        grades: grades,
      );
    }).toList();
  }

  static String _formatHadithNumber(Object? value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    if (value is double && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class HadithApiException implements Exception {
  final String message;
  HadithApiException(this.message);

  @override
  String toString() => message;
}

class Hadith {
  final String hadithNumber;
  final String text;
  final String chapterTitle;
  final List<String> grades;

  Hadith({
    required this.hadithNumber,
    required this.text,
    required this.chapterTitle,
    required this.grades,
  });
}
