import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/personal_event.dart';

class PersonalEventStore {
  static const _key = 'personal_events_v1';

  Future<List<PersonalEvent>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(PersonalEvent.fromJson)
          .where((x) => x.title.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<PersonalEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(events.map((x) => x.toJson()).toList()));
  }
}
