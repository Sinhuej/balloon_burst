import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_profile.dart';
import '../models/player_stats.dart';

/// ProfileStore
/// - SharedPreferences only
/// - JSON strings stored under stable keys
/// - Safe defaults if missing/corrupt
/// - No UI / engine wiring here
class ProfileStore {
  static const String _kProfileJson = 'bb_profile_json_v1';
  static const String _kStatsJson = 'bb_stats_json_v1';

  const ProfileStore();

  Future<PlayerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfileJson);
    if (raw == null || raw.trim().isEmpty) {
      return _defaultProfile();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PlayerProfile.fromJson(decoded);
      }
      // If something weird got stored, fall back safely.
      return _defaultProfile();
    } catch (_) {
      return _defaultProfile();
    }
  }

  Future<void> saveProfile(PlayerProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(p.toJson());
    await prefs.setString(_kProfileJson, jsonStr);
  }

  Future<PlayerStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStatsJson);
    if (raw == null || raw.trim().isEmpty) {
      return _defaultStats();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PlayerStats.fromJson(decoded);
      }
      return _defaultStats();
    } catch (_) {
      return _defaultStats();
    }
  }

  Future<void> saveStats(PlayerStats s) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(s.toJson());
    await prefs.setString(_kStatsJson, jsonStr);
  }

  /// Optional but preferred: wipe only what we own.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileJson);
    await prefs.remove(_kStatsJson);
  }

  PlayerProfile _defaultProfile() {
    // Prefer your model's own defaults. Most TJ-style models accept {} safely.
    try {
      return PlayerProfile.fromJson(const <String, dynamic>{});
    } catch (_) {
      // If your model is stricter, update PlayerProfile.fromJson to tolerate missing fields.
      // We intentionally do not invent constructor params here to avoid breaking changes.
      rethrow;
    }
  }

  PlayerStats _defaultStats() {
    try {
      return PlayerStats.fromJson(const <String, dynamic>{});
    } catch (_) {
      rethrow;
    }
  }
}
