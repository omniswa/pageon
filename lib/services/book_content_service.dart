import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../models/chapter.dart';

class ChapterCooldownException implements Exception {
  final Duration remaining;
  ChapterCooldownException(this.remaining);

  @override
  String toString() =>
      'Please wait ${remaining.inSeconds + 1}s before trying again.';
}

/// Downloads a book's zip, extracts chapters, caches them, and rate-limits.
class BookContentService {
  static const Duration cooldown = Duration(seconds: 15);
  static const String _baseUrl = 'https://3nding.top/';

  // One cooldown per book so refreshing one doesn't block another.
  final Map<int, DateTime> _lastAttempt = {};

  String _cacheKey(int bookId) => 'book_chapters_v1_$bookId';

  Future<List<Chapter>?> loadCached(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(bookId));
      if (raw == null) return null;
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Chapter cache read failed: $e');
      return null;
    }
  }

  Future<List<Chapter>> fetchAndExtract(Book book, {bool force = false}) async {
    final now = DateTime.now();
    final last = _lastAttempt[book.id];
    if (!force && last != null) {
      final elapsed = now.difference(last);
      if (elapsed < cooldown) throw ChapterCooldownException(cooldown - elapsed);
    }
    _lastAttempt[book.id] = now;

    final response =
        await http.get(_resolveZipUrl(book.zip)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final chapters = _extractChapters(response.bodyBytes);
    if (chapters.isEmpty) {
      throw Exception('No chapter files were found in this book.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey(book.id),
        jsonEncode(chapters.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Chapter cache write failed: $e');
    }
    return chapters;
  }

  List<Chapter> _extractChapters(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final chapterExp = RegExp(r'(\d+)\.txt$', caseSensitive: false);
    final chapters = <Chapter>[];

    for (final entry in archive.files) {
      if (!entry.isFile) continue;
      final match = chapterExp.firstMatch(entry.name.split('/').last);
      if (match == null) continue;
      final number = int.parse(match.group(1)!);
      chapters.add(Chapter(
        number: number,
        title: 'Chapter $number',
        content: utf8.decode(entry.content as List<int>, allowMalformed: true),
      ));
    }
    chapters.sort((a, b) => a.number.compareTo(b.number));
    return chapters;
  }

  /// `zip` may be absolute or relative to the host serving books.json.
  Uri _resolveZipUrl(String zip) =>
      zip.startsWith('http://') || zip.startsWith('https://')
          ? Uri.parse(zip)
          : Uri.parse('$_baseUrl$zip');
}
