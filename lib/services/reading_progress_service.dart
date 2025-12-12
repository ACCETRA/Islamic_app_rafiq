import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressService {
  static const String _lastReadKey = 'last_read_position';
  static const String _readingHistoryKey = 'reading_history';
  static const String _dailyStreakKey = 'daily_streak';
  static const String _lastReadDateKey = 'last_read_date';

  // Save last read position
  static Future<void> savePosition({
    required int surahNumber,
    required String surahName,
    required int verseNumber,
    required int totalVerses,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'verseNumber': verseNumber,
      'totalVerses': totalVerses,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_lastReadKey, json.encode(data));

    // Update reading history
    await _addToHistory(surahNumber, surahName);

    // Update streak
    await _updateStreak();
  }

  // Get last read position
  static Future<Map<String, dynamic>?> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_lastReadKey);

    if (dataStr != null) {
      return json.decode(dataStr);
    }
    return null;
  }

  // Get reading progress percentage
  static Future<double> getProgressPercentage() async {
    final position = await getLastPosition();
    if (position == null) return 0.0;

    final verse = position['verseNumber'] as int;
    final total = position['totalVerses'] as int;
    return verse / total;
  }

  // Add to reading history
  static Future<void> _addToHistory(int surahNumber, String surahName) async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString(_readingHistoryKey);

    List<Map<String, dynamic>> history = [];
    if (historyStr != null) {
      history = List<Map<String, dynamic>>.from(json.decode(historyStr));
    }

    // Add new entry
    history.insert(0, {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 20 entries
    if (history.length > 20) {
      history = history.sublist(0, 20);
    }

    await prefs.setString(_readingHistoryKey, json.encode(history));
  }

  // Get reading history
  static Future<List<Map<String, dynamic>>> getReadingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString(_readingHistoryKey);

    if (historyStr != null) {
      return List<Map<String, dynamic>>.from(json.decode(historyStr));
    }
    return [];
  }

  // Update daily streak
  static Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastReadDateKey);
    final currentStreak = prefs.getInt(_dailyStreakKey) ?? 0;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastDateStr == null) {
      // First time reading
      await prefs.setInt(_dailyStreakKey, 1);
      await prefs.setString(_lastReadDateKey, todayStr);
    } else if (lastDateStr != todayStr) {
      // Check if it was yesterday
      final parts = lastDateStr.split('-');
      final lastDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        // Consecutive day - increase streak
        await prefs.setInt(_dailyStreakKey, currentStreak + 1);
      } else if (difference > 1) {
        // Missed a day - reset streak
        await prefs.setInt(_dailyStreakKey, 1);
      }

      await prefs.setString(_lastReadDateKey, todayStr);
    }
  }

  // Get current streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyStreakKey) ?? 0;
  }

  // Clear reading progress
  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastReadKey);
    await prefs.remove(_readingHistoryKey);
    await prefs.remove(_dailyStreakKey);
    await prefs.remove(_lastReadDateKey);
  }

  // Get formatted time since last read
  static String getTimeSinceLastRead(String timestamp) {
    final lastRead = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastRead);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
