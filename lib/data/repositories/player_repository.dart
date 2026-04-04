import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_stats_model.dart';

/// Accès aux statistiques du joueur : lecture/écriture Hive + sync Supabase.
/// Pas d'état UI — retourne des objets ou lance des exceptions.
class PlayerRepository {
  final Box _statsBox;
  final SupabaseClient _supabase;

  PlayerRepository(this._statsBox, this._supabase);

  /// Charge les stats depuis Hive (rapide, offline-first).
  PlayerStats loadLocalStats() {
    try {
      final json = _statsBox.get('stats');
      if (json != null) {
        return PlayerStats.fromJson(Map<String, dynamic>.from(json as Map));
      }
    } catch (e) {
      debugPrint('PlayerRepository: erreur lecture Hive: $e');
    }
    return PlayerStats();
  }

  /// Sauvegarde les stats dans Hive.
  Future<void> saveLocalStats(PlayerStats stats) async {
    try {
      await _statsBox.put('stats', stats.toJson());
    } catch (e) {
      debugPrint('PlayerRepository: erreur écriture Hive: $e');
    }
  }

  /// Récupère les stats depuis Supabase (peut retourner null si absentes).
  Future<PlayerStats?> fetchRemoteStats(String userId) async {
    final response = await _supabase
        .from('player_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return PlayerStats.fromSupabaseMap(Map<String, dynamic>.from(response));
  }

  /// Synchronise les stats vers Supabase (best-effort, ne bloque pas l'UI).
  Future<void> syncToSupabase(String userId, PlayerStats stats) async {
    try {
      await _supabase.from('player_stats').upsert({
        'user_id': userId,
        ...stats.toSupabaseMap(),
      });
    } catch (e) {
      debugPrint('PlayerRepository: erreur sync Supabase: $e');
    }
  }
}
