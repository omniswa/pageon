import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../models/reading_progress.dart';

/// The user's personal library state: favorites and reading progress.
/// Both survive app restarts.
class LibraryStore extends ChangeNotifier {
  static const String _favoritesKey = 'favorites_v1';
  static const String _progressKey = 'reading_progress_v1';

  final Set<int> _favorites = {};
  final Map<int, ReadingProgress> _progress = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final favs = prefs.getStringList(_favoritesKey) ?? const [];
      _favorites.addAll(favs.map(int.tryParse).whereType<int>());

      final raw = prefs.getString(_progressKey);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((id, json) {
          final key = int.tryParse(id);
          if (key != null) {
            _progress[key] =
                ReadingProgress.fromJson(json as Map<String, dynamic>);
          }
        });
      }
    } catch (e) {
      debugPrint('Library load failed: $e');
    }
    notifyListeners();
  }

  // ---- Favorites ----------------------------------------------------------

  bool isFavorite(int bookId) => _favorites.contains(bookId);

  List<Book> favoritesOf(List<Book> books) =>
      books.where((b) => _favorites.contains(b.id)).toList();

  Future<void> toggleFavorite(int bookId) async {
    if (!_favorites.remove(bookId)) _favorites.add(bookId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoritesKey,
        _favorites.map((e) => '$e').toList(),
      );
    } catch (e) {
      debugPrint('Favorites save failed: $e');
    }
  }

  // ---- Progress -----------------------------------------------------------

  ReadingProgress? progressFor(int bookId) => _progress[bookId];

  /// The book the user touched most recently, if any.
  Book? lastReadOf(List<Book> books) {
    Book? latest;
    for (final book in books) {
      final p = _progress[book.id];
      if (p == null) continue;
      final best = latest == null ? null : _progress[latest.id];
      if (best == null || p.updatedAt.isAfter(best.updatedAt)) latest = book;
    }
    return latest;
  }

  Future<void> saveProgress(int bookId, ReadingProgress progress) async {
    _progress[bookId] = progress;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _progressKey,
        jsonEncode(_progress.map((k, v) => MapEntry('$k', v.toJson()))),
      );
    } catch (e) {
      debugPrint('Progress save failed: $e');
    }
  }
}
