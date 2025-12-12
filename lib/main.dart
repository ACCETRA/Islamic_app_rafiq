import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:adhan/adhan.dart' as adhan;
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip database initialization on web platform
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic Companion',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Amiri',
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

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

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final isLoggedIn = await AuthService.init();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF128C7E),
              const Color(0xFF0D6E6E),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mosque_rounded,
                    size: 70, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rafiq',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Islamic Companion',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const QuranScreen(),
    const PrayerScreen(),
    const QiblaScreen(),
    const AzkarScreen(),
    const TasbihScreen(),
    const CalendarScreen(),
    const HadithScreen(),
    const DuaScreen(),
    const FastingTrackerScreen(),
    const ZakatCalculatorScreen(),
    const HajjGuideScreen(),
    const LearningResourcesScreen(),
    const MapScreen(),
    const CommunityScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Quran'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Prayer'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Qibla'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Azkar'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Tasbih'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.format_quote), label: 'Hadith'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Duas'),
          NavigationDestination(icon: Icon(Icons.fastfood), label: 'Fasting'),
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Zakat'),
          NavigationDestination(
              icon: Icon(Icons.airplanemode_active), label: 'Hajj'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ==================== BOOKMARK SCREEN ====================
class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await DatabaseHelper.instance.getBookmarks();
    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? const Center(child: Text('No bookmarks yet'))
              : ListView.builder(
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = _bookmarks[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                            '${bookmark['surah_name']} - ${bookmark['ayah_number']}'),
                        subtitle:
                            Text(bookmark['ayah_text'] as String, maxLines: 2),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await DatabaseHelper.instance
                                .deleteBookmark(bookmark['id'] as int);
                            _loadBookmarks();
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  SurahDetailScreen(
                                surahNumber: bookmark['surah_number'] as int,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: QuranSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BookmarkScreen()));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedTranslation = value),
            itemBuilder: (context) => _translations
                .map((t) => PopupMenuItem<String>(
                      value: t['code'] as String,
                      child: Text(t['name'] as String),
                    ))
                .toList(),
            child: const Icon(Icons.translate),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: quran.totalSurahCount,
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(child: Text('$surahNumber')),
              title: Text(quran.getSurahNameEnglish(surahNumber)),
              subtitle: Text(quran.getSurahNameArabic(surahNumber),
                  style: const TextStyle(fontSize: 20)),
              trailing: Text('${quran.getVerseCount(surahNumber)} Ayahs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => SurahDetailScreen(
                      surahNumber: surahNumber,
                      translationCode: _selectedTranslation,
                      onPlayAudio: _playAyahAudio,
                      onPlayTTS: _playAyahTTS,
                      onBookmark: _addBookmark,
                    ),
                  ),
                );
              },
            ),
          );
        },
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
                    style: const TextStyle(fontSize: 22, fontFamily: 'Amiri'),
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
  List<Map<String, dynamic>> _hadiths = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    setState(() => _isLoading = true);
    try {
      _hadiths = [
        {
          'hadithNumber': '1',
          'chapter': 'Introduction',
          'text':
              'Actions are judged by intentions, so each man will have what he intended.',
        },
        {
          'hadithNumber': '2',
          'chapter': 'Faith',
          'text':
              'Islam is built upon five: to worship Allah and to disbelieve in what is worshipped besides Him.',
        },
        {
          'hadithNumber': '3',
          'chapter': 'Purification',
          'text':
              'Cleanliness is half of faith, and Alhamdulillah fills the scale.',
        },
      ];
    } catch (e) {
      _hadiths = [];
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith Collection'),
        actions: [
          DropdownButton<String>(
            value: _selectedCollection,
            items: _collections
                .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCollection = value!);
              _loadHadiths();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _hadiths.length,
              itemBuilder: (BuildContext context, index) {
                final hadith = _hadiths[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text('Hadith #${hadith['hadithNumber'] as String}'),
                    subtitle:
                        Text(hadith['chapter'] as String? ?? '', maxLines: 1),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hadith['text'] as String? ?? '',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {
                                    final text =
                                        '${hadith['text'] as String? ?? ''}\n\nSource: ${_selectedCollection.toUpperCase()}';
                                    SharePlus.instance
                                        .share(ShareParams(text: text));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

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
    return Scaffold(
      appBar: AppBar(title: const Text('Duas & Supplications')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _categories.length,
        itemBuilder: (BuildContext context, index) {
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        DuaCategoryScreen(category: _categories[index]),
                  ),
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _categories[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        },
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
                    style: const TextStyle(fontSize: 20, fontFamily: 'Amiri'),
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

// ==================== FASTING TRACKER ====================
class FastingTrackerScreen extends StatefulWidget {
  const FastingTrackerScreen({super.key});

  @override
  State<FastingTrackerScreen> createState() => _FastingTrackerScreenState();
}

class _FastingTrackerScreenState extends State<FastingTrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _fastingDays = [];

  @override
  void initState() {
    super.initState();
    _loadFastingDays();
  }

  Future<void> _loadFastingDays() async {
    final days = await DatabaseHelper.instance
        .getFastingDays(_selectedDate.month, _selectedDate.year);
    setState(() => _fastingDays = days);
  }

  Future<void> _toggleFastingDay(DateTime date, String type) async {
    await DatabaseHelper.instance.saveFastingDay(date.toIso8601String(), type);
    _loadFastingDays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fasting Tracker')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Select Date',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        _loadFastingDays();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              padding: const EdgeInsets.all(16),
              children: List.generate(
                  DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day,
                  (index) {
                final day = index + 1;
                final date =
                    DateTime(_selectedDate.year, _selectedDate.month, day);
                final isFasting = _fastingDays
                    .any((d) => d['date'] == date.toIso8601String());

                return GestureDetector(
                  onTap: () => _toggleFastingDay(date, 'voluntary'),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isFasting ? Colors.teal : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isFasting ? Colors.white : Colors.black,
                          fontWeight:
                              isFasting ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ZAKAT CALCULATOR ====================
class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _debtsController = TextEditingController();
  double _zakatAmount = 0;
  bool _showResult = false;

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _investmentsController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  void _calculateZakat() {
    if (_formKey.currentState!.validate()) {
      final cash = double.tryParse(_cashController.text) ?? 0;
      final gold = double.tryParse(_goldController.text) ?? 0;
      final silver = double.tryParse(_silverController.text) ?? 0;
      final investments = double.tryParse(_investmentsController.text) ?? 0;
      final debts = double.tryParse(_debtsController.text) ?? 0;

      final totalWealth = cash + gold + silver + investments - debts;
      final nisab = 85 * 60;
      double zakat = 0;

      if (totalWealth >= nisab) {
        zakat = totalWealth * 0.025;
      }

      setState(() {
        _zakatAmount = zakat;
        _showResult = true;
      });

      DatabaseHelper.instance
          .saveZakatRecord(DateTime.now().year, totalWealth, zakat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zakat Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your assets and liabilities:',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cashController,
                decoration: const InputDecoration(
                    labelText: 'Cash in hand & bank (\$)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goldController,
                decoration: const InputDecoration(
                    labelText: 'Value of gold (\$)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _silverController,
                decoration: const InputDecoration(
                    labelText: 'Value of silver (\$)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _investmentsController,
                decoration: const InputDecoration(
                    labelText: 'Investments & stocks (\$)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _debtsController,
                decoration: const InputDecoration(
                    labelText: 'Debts owed (\$)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _calculateZakat,
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate Zakat'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              if (_showResult) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Your Zakat Amount:',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 12),
                        Text(
                          '\$${_zakatAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700),
                        ),
                        const SizedBox(height: 16),
                        const Text('2.5% of your qualifying wealth',
                            style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HAJJ GUIDE ====================
class HajjGuideScreen extends StatelessWidget {
  const HajjGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guideSteps = [
      {
        'step': 1,
        'title': 'Ihram',
        'description': 'Enter the sacred state of Ihram at the Miqat.'
      },
      {
        'step': 2,
        'title': 'Tawaf al-Qudum',
        'description': 'Perform the Welcome Tawaf upon arrival in Makkah.'
      },
      {
        'step': 3,
        'title': 'Sa\'i',
        'description': 'Walk between Safa and Marwa 7 times.'
      },
      {
        'step': 4,
        'title': 'Wuquf at Arafat',
        'description': 'Stand at Mount Arafat on 9th Dhul Hijjah.'
      },
      {
        'step': 5,
        'title': 'Muzdalifah',
        'description': 'Spend the night in Muzdalifah after Arafat.'
      },
      {
        'step': 6,
        'title': 'Rami',
        'description': 'Stone the Jamarat (devils) on 10th-12th Dhul Hijjah.'
      },
      {
        'step': 7,
        'title': 'Eid Sacrifice',
        'description': 'Perform animal sacrifice for Eid al-Adha.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hajj & Umrah Guide')),
      body: ListView.builder(
        itemCount: guideSteps.length,
        itemBuilder: (BuildContext context, index) {
          final step = guideSteps[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text('${step['step']}',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(step['title'] as String,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(step['description'] as String,
                  style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(step['title'] as String),
                    content: SingleChildScrollView(
                      child: Text(
                          'Detailed information about ${step['title'] as String} would be displayed here.'),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ==================== LEARNING RESOURCES ====================
class LearningResourcesScreen extends StatelessWidget {
  const LearningResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = [
      {'title': 'Islamic Basics', 'icon': Icons.school, 'color': Colors.blue},
      {
        'title': 'Fiqh (Jurisprudence)',
        'icon': Icons.gavel,
        'color': Colors.green
      },
      {
        'title': 'Seerah (Prophet\'s Life)',
        'icon': Icons.history,
        'color': Colors.orange
      },
      {
        'title': 'Tafsir Studies',
        'icon': Icons.menu_book,
        'color': Colors.purple
      },
      {
        'title': 'Hadith Studies',
        'icon': Icons.format_quote,
        'color': Colors.teal
      },
      {
        'title': 'Arabic Language',
        'icon': Icons.translate,
        'color': Colors.red
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Resources')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: resources.length,
        itemBuilder: (BuildContext context, index) {
          final resource = resources[index];
          final color = resource['color'] as Color;
          final icon = resource['icon'] as IconData;
          final title = resource['title'] as String;

          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening $title resources...')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== COMMUNITY SCREEN ====================
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Your Progress',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.share, color: Colors.teal),
                title: const Text('Share Quran Reading'),
                subtitle: const Text('Share your current surah progress'),
                onTap: () {
                  const text =
                      'I just read Surah Al-Fatihah in the Islamic Companion App! #Quran #Islam';
                  SharePlus.instance.share(ShareParams(text: text));
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
                title: const Text('Achievements'),
                subtitle: const Text('View your spiritual milestones'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Achievement system coming soon!')),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.blue),
                title: const Text('Study Groups'),
                subtitle: const Text('Join local or virtual study circles'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Study groups feature coming soon!')),
                  );
                },
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Community features are in development',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRAYER SCREEN ====================
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  late Future<Map<String, DateTime>> _prayerTimesFuture;
  Position? _currentLocation;
  adhan.CalculationMethod _selectedMethod =
      adhan.CalculationMethod.muslim_world_league;
  adhan.Madhab _selectedMadhab = adhan.Madhab.shafi;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request permission first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _prayerTimesFuture = _getPrayerTimes(location);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Default to Makkah coordinates
      _currentLocation = Position(
        latitude: 21.4225,
        longitude: 39.8262,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      if (mounted) {
        setState(() {
          _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Using default location (Makkah). Please enable location services for accurate prayer times.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<Map<String, DateTime>> _getPrayerTimes(Position position) async {
    try {
      // Get today's date
      final now = DateTime.now();

      // Create DateComponents for the adhan library (v2.0.0+)
      final dateComponents = adhan.DateComponents(now.year, now.month, now.day);

      // Create coordinates
      final coordinates = adhan.Coordinates(
        position.latitude,
        position.longitude,
      );

      // Get calculation parameters based on selected method
      final params = _selectedMethod.getParameters();
      params.madhab = _selectedMadhab;

      // Set high latitude rule for extreme latitudes
      params.highLatitudeRule = adhan.HighLatitudeRule.middle_of_the_night;

      // Calculate prayer times (precision parameter removed in v2.0.0+)
      final prayerTimes = adhan.PrayerTimes(
        coordinates,
        dateComponents,
        params,
      );

      // Convert to local time and return
      return {
        'Fajr': prayerTimes.fajr.toLocal(),
        'Sunrise': prayerTimes.sunrise.toLocal(),
        'Dhuhr': prayerTimes.dhuhr.toLocal(),
        'Asr': prayerTimes.asr.toLocal(),
        'Maghrib': prayerTimes.maghrib.toLocal(),
        'Isha': prayerTimes.isha.toLocal(),
      };
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
      throw Exception('Failed to calculate prayer times: $e');
    }
  }

// Replace the _showCalculationMethodDialog and _showMadhabDialog methods
// in your _PrayerScreenState class with these fixed versions:

  void _showCalculationMethodDialog() {
    final methods = [
      {
        'name': 'Muslim World League',
        'method': adhan.CalculationMethod.muslim_world_league
      },
      {'name': 'Egyptian', 'method': adhan.CalculationMethod.egyptian},
      {'name': 'Karachi', 'method': adhan.CalculationMethod.karachi},
      {
        'name': 'Umm Al-Qura (Makkah)',
        'method': adhan.CalculationMethod.umm_al_qura
      },
      {'name': 'Dubai', 'method': adhan.CalculationMethod.dubai},
      {
        'name': 'Moonsighting Committee',
        'method': adhan.CalculationMethod.moon_sighting_committee
      },
      {
        'name': 'North America (ISNA)',
        'method': adhan.CalculationMethod.north_america
      },
      {'name': 'Kuwait', 'method': adhan.CalculationMethod.kuwait},
      {'name': 'Qatar', 'method': adhan.CalculationMethod.qatar},
      {'name': 'Singapore', 'method': adhan.CalculationMethod.singapore},
      {'name': 'Turkey', 'method': adhan.CalculationMethod.turkey},
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        adhan.CalculationMethod tempMethod = _selectedMethod;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Calculation Method'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: methods.length,
                  itemBuilder: (BuildContext context, int index) {
                    final method = methods[index];
                    final methodValue =
                        method['method'] as adhan.CalculationMethod;

                    return ListTile(
                      title: Text(method['name'] as String),
                      leading: Radio<adhan.CalculationMethod>(
                        value: methodValue,
                        groupValue: tempMethod,
                        onChanged: (adhan.CalculationMethod? value) {
                          if (value != null) {
                            setDialogState(() {
                              tempMethod = value;
                            });
                          }
                        },
                      ),
                      onTap: () {
                        setDialogState(() {
                          tempMethod = methodValue;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMethod = tempMethod;
                    });
                    Navigator.pop(dialogContext);
                    if (_currentLocation != null) {
                      setState(() {
                        _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
                      });
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMadhabDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        adhan.Madhab tempMadhab = _selectedMadhab;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select Madhab (School of Thought)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Shafi\'i, Maliki, Hanbali'),
                    leading: Radio<adhan.Madhab>(
                      value: adhan.Madhab.shafi,
                      groupValue: tempMadhab,
                      onChanged: (adhan.Madhab? value) {
                        if (value != null) {
                          setDialogState(() {
                            tempMadhab = value;
                          });
                        }
                      },
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempMadhab = adhan.Madhab.shafi;
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('Hanafi'),
                    leading: Radio<adhan.Madhab>(
                      value: adhan.Madhab.hanafi,
                      groupValue: tempMadhab,
                      onChanged: (adhan.Madhab? value) {
                        if (value != null) {
                          setDialogState(() {
                            tempMadhab = value;
                          });
                        }
                      },
                    ),
                    onTap: () {
                      setDialogState(() {
                        tempMadhab = adhan.Madhab.hanafi;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMadhab = tempMadhab;
                    });
                    Navigator.pop(dialogContext);
                    if (_currentLocation != null) {
                      setState(() {
                        _prayerTimesFuture = _getPrayerTimes(_currentLocation!);
                      });
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showCalculationMethodDialog,
            tooltip: 'Calculation Method',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, DateTime>>(
        future: _prayerTimesFuture,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, DateTime>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Calculating prayer times...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 20),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                  'No prayer times available. Please check your location.'),
            );
          }

          final prayerTimes = snapshot.data!;
          final currentTime = DateTime.now();

          // Find next prayer
          String? nextPrayer;
          DateTime? nextPrayerTime;

          for (final entry in prayerTimes.entries) {
            if (entry.value.isAfter(currentTime)) {
              if (nextPrayerTime == null ||
                  entry.value.isBefore(nextPrayerTime)) {
                nextPrayer = entry.key;
                nextPrayerTime = entry.value;
              }
            }
          }

          // If no prayer found for today, get first prayer of tomorrow
          if (nextPrayer == null) {
            nextPrayer = 'Fajr';
            final tomorrow = DateTime.now().add(const Duration(days: 1));
            final tomorrowDateComponents = adhan.DateComponents(
                tomorrow.year, tomorrow.month, tomorrow.day);
            final coordinates = adhan.Coordinates(
              _currentLocation?.latitude ?? 21.4225,
              _currentLocation?.longitude ?? 39.8262,
            );
            final params = _selectedMethod.getParameters();
            params.madhab = _selectedMadhab;
            params.highLatitudeRule =
                adhan.HighLatitudeRule.middle_of_the_night;

            final tomorrowPrayerTimes = adhan.PrayerTimes(
              coordinates,
              tomorrowDateComponents,
              params,
            );
            nextPrayerTime = tomorrowPrayerTimes.fajr.toLocal();
          }

          final timeUntilNextPrayer = nextPrayerTime!.difference(currentTime);
          final hours = timeUntilNextPrayer.inHours;
          final minutes = timeUntilNextPrayer.inMinutes % 60;

          return Column(
            children: [
              // Location info
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.teal),
                        title: const Text('Location',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _currentLocation != null
                              ? 'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, '
                                  'Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}'
                              : 'Location not available',
                        ),
                        trailing: ElevatedButton(
                          onPressed: _showMadhabDialog,
                          child: Text(_selectedMadhab == adhan.Madhab.hanafi
                              ? 'Hanafi'
                              : 'Shafi\'i'),
                        ),
                      ),
                      if (_currentLocation == null ||
                          (_currentLocation!.latitude == 21.4225 &&
                              _currentLocation!.longitude == 39.8262))
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Using default Makkah location. Enable GPS for accurate times.',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Next prayer card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Prayer',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(nextPrayer,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(nextPrayerTime),
                          style:
                              const TextStyle(fontSize: 18, color: Colors.teal),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Time Remaining',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '${hours}h ${minutes}m',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prayer times list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: prayerTimes.entries.map((entry) {
                    final prayerName = entry.key;
                    final prayerTime = entry.value;
                    final isPast = prayerTime.isBefore(currentTime);
                    final isNext = prayerName == nextPrayer;

                    return Card(
                      elevation: isNext ? 4 : 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isNext
                          ? Colors.teal.withValues(alpha: 0.1)
                          : (isPast ? Colors.grey[100] : null),
                      shape: isNext
                          ? RoundedRectangleBorder(
                              side: BorderSide(color: Colors.teal, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isNext ? Colors.teal : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _getPrayerIcon(prayerName),
                            color: isNext ? Colors.white : Colors.grey[700],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          prayerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isNext ? FontWeight.bold : FontWeight.normal,
                            color: isNext ? Colors.teal : null,
                          ),
                        ),
                        subtitle: isPast
                            ? const Text('Prayed',
                                style: TextStyle(color: Colors.green))
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('h:mm').format(prayerTime),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: isNext
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isNext ? Colors.teal : null,
                              ),
                            ),
                            Text(
                              DateFormat('a').format(prayerTime).toLowerCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isNext ? Colors.teal : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'Fajr':
        return Icons.nightlight;
      case 'Sunrise':
        return Icons.wb_sunny;
      case 'Dhuhr':
        return Icons.brightness_5;
      case 'Asr':
        return Icons.brightness_6;
      case 'Maghrib':
        return Icons.nightlight_round;
      case 'Isha':
        return Icons.nightlight;
      default:
        return Icons.access_time;
    }
  }
}

// ==================== QIBLA SCREEN (FIXED) ====================
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Position? _currentLocation;
  double _qiblaDirection = 0;
  double _deviceHeading = 0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompassSupport = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCompass() async {
    // Check if compass is available
    final compassStream = FlutterCompass.events;

    if (compassStream == null) {
      setState(() {
        _hasCompassSupport = false;
        _errorMessage = 'Compass not supported on this device';
      });
      return;
    }

    setState(() {
      _hasCompassSupport = true;
    });

    // Listen to compass events
    _compassSubscription = compassStream.listen(
      (CompassEvent event) {
        if (event.heading != null) {
          setState(() {
            _deviceHeading = event.heading!;
          });
        }
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Compass error: $error';
        });
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // Get current location
      final location = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _qiblaDirection = _calculateQiblaDirection(location);
          _errorMessage = '';
        });
      }
    } catch (e) {
      // Default to Makkah coordinates
      _currentLocation = Position(
        latitude: 21.4225,
        longitude: 39.8262,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      if (mounted) {
        setState(() {
          _qiblaDirection = _calculateQiblaDirection(_currentLocation!);
          _errorMessage = 'Using default location (Makkah): $e';
        });
      }
    }
  }

  double _calculateQiblaDirection(Position position) {
    const meccaLat = 21.4225;
    const meccaLon = 39.8262;

    final lat = position.latitude * pi / 180;
    final lon = position.longitude * pi / 180;
    final meccaLatRad = meccaLat * pi / 180;
    final meccaLonRad = meccaLon * pi / 180;

    final deltaLon = meccaLonRad - lon;

    final y = sin(deltaLon) * cos(meccaLatRad);
    final x = cos(lat) * sin(meccaLatRad) -
        sin(lat) * cos(meccaLatRad) * cos(deltaLon);

    final bearing = atan2(y, x);
    final qibla = (bearing * 180 / pi + 360) % 360;

    return qibla;
  }

  // Calculate the rotation angle for the compass needle
  double get _needleRotation {
    // The needle should point to Qibla
    // Subtract device heading from Qibla direction to get relative angle
    double rotation = _qiblaDirection - _deviceHeading;

    // Normalize to -180 to 180 range for smoother rotation
    while (rotation > 180) {
      rotation -= 360;
    }
    while (rotation < -180) {
      rotation += 360;
    }

    return rotation * pi / 180; // Convert to radians
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.orange.shade900),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Location info
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Current Location',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Compass display
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Compass rose background
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: CustomPaint(
                            painter: CompassRosePainter(),
                          ),
                        ),

                        // Rotating needle pointing to Qibla
                        if (_hasCompassSupport)
                          Transform.rotate(
                            angle: _needleRotation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.navigation,
                                  size: 80,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Qibla',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (!_hasCompassSupport)
                          const Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Direction info
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Qibla Direction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_qiblaDirection.toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              if (_hasCompassSupport)
                                Column(
                                  children: [
                                    const Text(
                                      'Device Heading',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_deviceHeading.toStringAsFixed(1)}°',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (!_hasCompassSupport) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Compass not available on this device.\nPlease use the angle shown above to face Qibla.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Instructions
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Hold your device flat and rotate until the green arrow points upward.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom painter for compass rose
class CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw cardinal direction markers
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final x1 = center.dx + (radius - 30) * cos(angle);
      final y1 = center.dy + (radius - 30) * sin(angle);
      final x2 = center.dx + (radius - 10) * cos(angle);
      final y2 = center.dy + (radius - 10) * sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw minor direction markers
    paint.strokeWidth = 1;
    for (int i = 0; i < 12; i++) {
      if (i % 3 != 0) {
        final angle = i * pi / 6;
        final x1 = center.dx + (radius - 20) * cos(angle);
        final y1 = center.dy + (radius - 20) * sin(angle);
        final x2 = center.dx + (radius - 10) * cos(angle);
        final y2 = center.dy + (radius - 10) * sin(angle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

  void _nextAzkar() {
    final azkarList = azkarData.entries.first.value;
    if (_currentAzkarIndex < azkarList.length - 1) {
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
            tabs: azkarData.entries.map((e) => Tab(text: e.key)).toList(),
          ),
        ),
        body: TabBarView(
          children: azkarData.entries.map((entry) {
            final list = entry.value;
            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      list[_currentAzkarIndex]['arabic'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 24, height: 1.8),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                        list[_currentAzkarIndex]
                                                ['translation'] ??
                                            '',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                    onPressed: _previousAzkar,
                                    icon: const Icon(Icons.skip_previous)),
                                Text(
                                    '${_currentAzkarIndex + 1} / ${list.length}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                    onPressed: _nextAzkar,
                                    icon: const Icon(Icons.skip_next)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (entry.key == 'Prayer')
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Tasbih Counter',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (BuildContext context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: GestureDetector(
                                  onTap: _incrementCount,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            spreadRadius: 5)
                                      ],
                                    ),
                                    child: Center(
                                      child: Text('$_count / $_targetCount',
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                  onPressed: _incrementCount,
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder()),
                                  child: const Icon(Icons.add)),
                              ElevatedButton(
                                  onPressed: _resetCount,
                                  style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder()),
                                  child: const Icon(Icons.refresh)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
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
      'arabic': 'اللّهُـمَّ بِكَ أَصْبَحْـنا',
      'translation': 'O Allah, by You we enter the morning.'
    },
    {
      'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
      'translation': 'I seek refuge in the perfect words of Allah.'
    },
    {
      'arabic': 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      'translation': 'Allah is sufficient for me, there is no deity except Him.'
    },
    {
      'arabic': 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ',
      'translation': 'In the name of Allah with whose name nothing harms.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ',
      'translation': 'O Allah, I seek the best from You.'
    },
    {
      'arabic': 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ',
      'translation': 'O Allah, You are my Lord, there is no deity except You.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا',
      'translation': 'O Allah, I ask You for beneficial knowledge.'
    },
    {
      'arabic': 'اللَّهُمَّ عَافِنِي فِي بَدَنِي',
      'translation': 'O Allah, grant me health in my body.'
    },
    {
      'arabic': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
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
      'arabic': 'اللّهُـمَّ بِكَ أَمْسَـينا',
      'translation': 'O Allah, by You we enter the evening.'
    },
    {
      'arabic': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
      'translation': 'I seek refuge in the perfect words of Allah.'
    },
    {
      'arabic': 'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
      'translation': 'Allah is sufficient for me, there is no deity except Him.'
    },
    {
      'arabic': 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ',
      'translation': 'In the name of Allah with whose name nothing harms.'
    },
    {
      'arabic': 'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ',
      'translation': 'O Allah, I seek the best from You.'
    },
  ],
  'Prayer': [
    {'arabic': 'سُبْحَانَ اللَّهِ', 'translation': 'Glory be to Allah.'},
    {
      'arabic': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      'translation': 'Glory be to Allah and praise is due to Him.'
    },
    {
      'arabic': 'سُبْحَانَ اللَّهِ الْعَظِيمِ',
      'translation': 'Glory be to Allah, the Almighty.'
    },
  ],
};

// ==================== CALENDAR SCREEN ====================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.fromDate(_currentDate);
    final daysInMonth =
        DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentDate.year, _currentDate.month, 1).weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Calendar'),
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              onPressed: () => setState(() => _currentDate = DateTime.now())),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(DateFormat('MMMM y').format(_currentDate),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${hijri.getLongMonthName()} ${hijri.hYear} AH',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              padding: const EdgeInsets.all(16),
              children: List.generate(daysInMonth + firstWeekday, (index) {
                if (index < firstWeekday) return const SizedBox();
                final day = index - firstWeekday + 1;
                final isToday = _currentDate.day == day &&
                    _currentDate.month == DateTime.now().month;
                final date =
                    DateTime(_currentDate.year, _currentDate.month, day);
                final hijriDay = HijriCalendar.fromDate(date);
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.teal : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: TextStyle(
                                color: isToday ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold)),
                        Text(hijriDay.hDay.toString(),
                            style: TextStyle(
                                fontSize: 12,
                                color: isToday
                                    ? Colors.white70
                                    : Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MAP SCREEN ====================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentLocation;
  bool _isLoading = true;
  String _selectedType = 'mosque';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
      setState(() => _isLoading = false);
    } catch (e) {
      _currentLocation = Position(
        latitude: 21.4225,
        longitude: 39.8262,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Places'),
        actions: [
          DropdownButton<String>(
            value: _selectedType,
            items: ['mosque', 'halal', 'islamic_shop']
                .map((type) => DropdownMenuItem(
                    value: type, child: Text(type.toUpperCase())))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedType = value!);
            },
          ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _getCurrentLocation),
        ],
      ),
      body: _isLoading || _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Map functionality requires additional packages',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                      'Current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Refresh Location'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==================== TASBIH SCREEN ====================
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  final int _targetCount = 33;
  int _totalCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final List<String> _tasbihTypes = [
    'Subhanallah',
    'Alhamdulillah',
    'Allahu Akbar',
    'La ilaha illallah'
  ];
  int _currentTasbihType = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalCount = prefs.getInt('tasbih_total') ?? 0);
  }

  Future<void> _saveTotalCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tasbih_total', _totalCount);
  }

  void _incrementCount() {
    setState(() {
      _count++;
      _totalCount++;
      if (_count > _targetCount) _count = 1;
    });
    _controller.forward().then((_) => _controller.reverse());
    if (_count == _targetCount) Vibration.vibrate(duration: 100);
    _saveTotalCount();
  }

  void _resetCount() => setState(() => _count = 0);

  void _nextTasbihType() {
    setState(() {
      _currentTasbihType = (_currentTasbihType + 1) % _tasbihTypes.length;
      _count = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasbih Counter')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Today\'s Total',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('$_totalCount',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_tasbihTypes[_currentTasbihType],
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (BuildContext context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: GestureDetector(
                          onTap: _incrementCount,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 5)
                              ],
                            ),
                            child: Center(
                              child: Text('$_count / $_targetCount',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                          onPressed: _nextTasbihType,
                          icon: const Icon(Icons.skip_next, size: 40)),
                      IconButton(
                          onPressed: _resetCount,
                          icon: const Icon(Icons.refresh, size: 40)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _language = 'English';
  double _quranFontSize = 18;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _language = prefs.getString('language') ?? 'English';
      _quranFontSize = prefs.getDouble('quran_font_size') ?? 18;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setString('language', _language);
    await prefs.setDouble('quran_font_size', _quranFontSize);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _isDarkMode,
              onChanged: (value) => setState(() => _isDarkMode = value),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Language'),
              subtitle: Text(_language),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Select Language'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        ['English', 'Arabic', 'Urdu', 'Indonesian', 'Turkish']
                            .map((lang) => RadioMenuButton<String>(
                                  value: lang,
                                  groupValue: _language,
                                  onChanged: (value) {
                                    setState(() => _language = value!);
                                    Navigator.pop(context);
                                  },
                                  child: Text(lang),
                                ))
                            .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                    title: const Text('Quran Font Size'),
                    subtitle: Text('${_quranFontSize.toInt()}')),
                Slider(
                    value: _quranFontSize,
                    min: 14,
                    max: 30,
                    divisions: 8,
                    onChanged: (value) =>
                        setState(() => _quranFontSize = value)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('About'),
              subtitle: const Text('Islamic Companion v1.0.0'),
              trailing: const Icon(Icons.info),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Islamic Companion',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.mosque, size: 48),
                children: [
                  const Text(
                      'A comprehensive Islamic app with Quran, prayer times, and spiritual tools.')
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }
}
