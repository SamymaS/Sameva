import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ActivityType { quest, levelUp, item, achievement, streak }

class ActivityLogEntry {
  final ActivityType type;
  final String title;
  final String? subtitle;
  final DateTime date;

  const ActivityLogEntry({
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'date': date.toIso8601String(),
      };

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      ActivityLogEntry(
        type: ActivityType.values.byName(json['type'] as String),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        date: DateTime.parse(json['date'] as String),
      );
}

/// Stocke jusqu'à 50 entrées d'activité dans la Hive box 'settings'.
class ActivityLogService {
  static const _key = 'activity_log';
  static const _maxEntries = 50;

  static Box get _box => Hive.box('settings');

  static List<ActivityLogEntry> getLog() {
    try {
      final raw = _box.get(_key);
      if (raw == null) return [];
      final list = (raw is String ? jsonDecode(raw) : raw) as List;
      return list
          .map((e) => ActivityLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addEntry(ActivityLogEntry entry) async {
    try {
      final log = getLog();
      log.insert(0, entry);
      if (log.length > _maxEntries) log.removeRange(_maxEntries, log.length);
      await _box.put(_key, jsonEncode(log.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('ActivityLogService: erreur écriture entrée: $e');
    }
  }

  static Future<void> clearLog() async {
    await _box.delete(_key);
  }
}
