import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reader_settings.dart';

class ReaderSettingsStore extends ChangeNotifier {
  static const String _key = 'reader_settings_v1';

  ReaderSettings _value = const ReaderSettings();
  ReaderSettings get value => _value;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _value = ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Reader settings load failed: $e');
    }
    notifyListeners();
  }

  Future<void> update(ReaderSettings Function(ReaderSettings) change) async {
    _value = change(_value);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_value.toJson()));
    } catch (e) {
      debugPrint('Reader settings save failed: $e');
    }
  }
}
