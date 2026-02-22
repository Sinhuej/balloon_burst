import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard_entry.dart';

class LeaderboardManager {
  static const _storageKey = 'tj_leaderboard_v1';
  static const int maxEntries = 10;

  List<LeaderboardEntry> _entries = [];

  List<LeaderboardEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      _entries = [];
      return;
    }

    final List<dynamic> decoded = jsonDecode(raw);
    _entries = decoded
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    _sortAndTrim();
  }

  Future<int?> submit(LeaderboardEntry entry) async {
    _entries.add(entry);
    _sortAndTrim();

    final placement = _entries.indexOf(entry);

    if (placement >= maxEntries) {
      _entries.remove(entry);
      return null;
    }

    await _persist();
    return placement + 1; // 1-based ranking for UI
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  void _sortAndTrim() {
    _entries.sort((a, b) => b.score.compareTo(a.score));
    if (_entries.length > maxEntries) {
      _entries = _entries.take(maxEntries).toList();
    }
  }
}
