import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'surah_detail_screen.dart';

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

