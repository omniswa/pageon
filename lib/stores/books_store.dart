import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// Owns the catalogue: disk cache, network refresh and refresh cooldown.
class BooksStore extends ChangeNotifier {
  static const String _booksUrl = 'https://3nding.top/books.json';
  static const String _cacheKey = 'books_cache_v1';
  static const String _cacheTimeKey = 'books_cache_time_v1';
  static const Duration cooldown = Duration(seconds: 30);

  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastUpdated;
  DateTime? _lastAttempt;

  List<Book> get books => _books;
  bool get isLoading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  /// Paints the cached catalogue first, then refreshes from the network.
  Future<void> bootstrap() async {
    await _loadCache();
    await refresh(force: true);
  }

  /// Returns a user-facing message when something worth showing happened
  /// (cooldown, failed refresh), otherwise null.
  Future<String?> refresh({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastAttempt != null) {
      final elapsed = now.difference(_lastAttempt!);
      if (elapsed < cooldown) {
        return 'Please wait ${(cooldown - elapsed).inSeconds + 1}s before refreshing again.';
      }
    }
    _lastAttempt = now;

    if (_books.isEmpty) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await http
          .get(Uri.parse(_booksUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
      _books = _parse(response.body);
      _lastUpdated = now;
      _error = null;
      _loading = false;
      notifyListeners();
      _saveCache(response.body, now);
      return null;
    } catch (e) {
      debugPrint('Books refresh failed: $e');
      _loading = false;
      final hadBooks = _books.isNotEmpty;
      _error = hadBooks ? null : 'Could not load books. Please try again.';
      notifyListeners();
      return hadBooks ? 'Refresh failed — showing your saved copy.' : null;
    }
  }

  List<Book> _parse(String body) => (jsonDecode(body) as List<dynamic>)
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      _books = _parse(raw);
      final ms = prefs.getInt(_cacheTimeKey);
      _lastUpdated = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Books cache read failed: $e');
    }
  }

  Future<void> _saveCache(String body, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      await prefs.setInt(_cacheTimeKey, at.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Books cache write failed: $e');
    }
  }
}
