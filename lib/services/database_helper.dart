import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

// ==================== DATABASE HELPER ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // SQLite not supported on web
    if (_database != null) return _database!;
    _database = await _initDB('islamic_app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, fileName);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        surah_name TEXT NOT NULL,
        ayah_text TEXT NOT NULL,
        translation TEXT,
        added_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY,
        surah_number INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        last_read_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fasting_days (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        completed INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE zakat_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        total_wealth REAL NOT NULL,
        zakat_amount REAL NOT NULL,
        paid_date TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE bookmarks ADD COLUMN translation TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
          'CREATE TABLE fasting_days (id TEXT PRIMARY KEY, date TEXT NOT NULL, type TEXT NOT NULL, completed INTEGER NOT NULL)');
      await db.execute(
          'CREATE TABLE zakat_records (id INTEGER PRIMARY KEY AUTOINCREMENT, year INTEGER NOT NULL, total_wealth REAL NOT NULL, zakat_amount REAL NOT NULL, paid_date TEXT)');
    }
  }

  Future<int> addBookmark(Map<String, dynamic> bookmark) async {
    if (kIsWeb) return 0; // Skip on web
    final db = await instance.database;
    if (db == null) return 0;
    return await db.insert('bookmarks', bookmark);
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    if (kIsWeb) return []; // Skip on web
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('bookmarks', orderBy: 'added_date DESC');
  }

  Future<int> deleteBookmark(int id) async {
    if (kIsWeb) return 0; // Skip on web
    final db = await instance.database;
    if (db == null) return 0;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveReadingProgress(int surah, int ayah) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    if (db == null) return;
    await db.insert(
        'reading_progress',
        {
          'id': 1,
          'surah_number': surah,
          'ayah_number': ayah,
          'last_read_date': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getReadingProgress() async {
    if (kIsWeb) return null; // Skip on web
    final db = await instance.database;
    if (db == null) return null;
    final results = await db.query('reading_progress', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> saveFastingDay(String date, String type) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    if (db == null) return;
    await db.insert('fasting_days',
        {'id': date, 'date': date, 'type': type, 'completed': 1},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getFastingDays(int month, int year) async {
    if (kIsWeb) return []; // Skip on web
    final db = await instance.database;
    if (db == null) return [];
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 1).toIso8601String();
    return await db.query('fasting_days',
        where: 'date >= ? AND date < ?', whereArgs: [startDate, endDate]);
  }

  Future<void> saveZakatRecord(int year, double wealth, double zakat) async {
    if (kIsWeb) return; // Skip on web
    final db = await instance.database;
    if (db == null) return;
    await db.insert('zakat_records', {
      'year': year,
      'total_wealth': wealth,
      'zakat_amount': zakat,
      'paid_date': DateTime.now().toIso8601String()
    });
  }

  Future<List<Map<String, dynamic>>> getZakatHistory() async {
    if (kIsWeb) return []; // Skip on web
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('zakat_records', orderBy: 'year DESC');
  }
}

