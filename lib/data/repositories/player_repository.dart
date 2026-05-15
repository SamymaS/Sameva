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

  /// Récupère les stats depuis Supabase.
  ///
  /// Trois comportements distincts :
  /// - Succès + ligne trouvée → retourne [PlayerStats]
  /// - Succès + aucune ligne (vrai nouveau user) → retourne null EXPLICITEMENT
  /// - Erreur réseau / exception Supabase → RELANCE l'exception (ne retourne jamais null dans ce cas)
  ///
  /// L'appelant doit attraper les exceptions pour distinguer l'absence de données
  /// d'une erreur réseau. Ne jamais appeler syncToSupabase si cette méthode a lancé.
  Future<PlayerStats?> fetchRemoteStats(String userId) async {
    // Pas de try/catch ici : on laisse remonter toute exception réseau.
    final response = await _supabase
        .from('player_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // null = requête réussie mais aucune ligne → nouveau utilisateur
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
