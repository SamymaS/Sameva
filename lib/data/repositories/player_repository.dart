import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player_stats_model.dart';
import 'game_api.dart';

/// Accès aux statistiques du joueur.
///
/// Sprint 1 : le serveur est l'unique autorité. Hive n'est plus qu'un cache
/// de lecture (affichage immédiat, hors-ligne) ; aucune écriture n'est jamais
/// envoyée vers `player_stats`.
class PlayerRepository {
  final Box _statsBox;
  final GameApi _api;

  PlayerRepository(this._statsBox, this._api);

  GameApi get api => _api;

  /// Charge le dernier état connu depuis le cache Hive.
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

  /// Met à jour le cache Hive.
  Future<void> saveLocalStats(PlayerStats stats) async {
    try {
      await _statsBox.put('stats', stats.toJson());
    } catch (e) {
      debugPrint('PlayerRepository: erreur écriture Hive: $e');
    }
  }

  /// Lit l'état faisant autorité (crée la ligne côté serveur si besoin).
  /// Propage les erreurs : l'appelant garde alors le cache.
  Future<PlayerServerState> fetchServerState() => _api.getPlayerState();
}
