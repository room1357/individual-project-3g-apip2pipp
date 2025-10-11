import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kExpenses = 'expenses';
  static const _kCategories = 'categories';
  static const _kCurrentUser = 'current_user';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---------- user ----------
  Future<void> setCurrentUser(String id) async {
    final p = await _prefs;
    await p.setString(_kCurrentUser, id);
  }

  Future<String?> getCurrentUser() async {
    final p = await _prefs;
    return p.getString(_kCurrentUser);
  }

  // ---------- list helpers ----------
  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final p = await _prefs;
    final raw = p.getStringList(key) ?? <String>[];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    final p = await _prefs;
    final encoded = list.map((m) => jsonEncode(m)).toList();
    await p.setStringList(key, encoded);
  }

  // ---------- expenses ----------
  Future<List<Map<String, dynamic>>> readExpenses() => _readList(_kExpenses);
  Future<void> writeExpenses(List<Map<String, dynamic>> data) =>
      _writeList(_kExpenses, data);

  // ---------- categories ----------
  Future<List<Map<String, dynamic>>> readCategories() =>
      _readList(_kCategories);
  Future<void> writeCategories(List<Map<String, dynamic>> data) =>
      _writeList(_kCategories, data);
}
