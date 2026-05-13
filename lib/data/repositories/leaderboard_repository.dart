import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';

/// Récupère le classement global depuis Supabase.
class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository(this._supabase);

  /// Retourne les [limit] meilleurs joueurs triés par niveau puis XP.
  /// Utilise la vue SQL [leaderboard_view] qui expose uniquement les colonnes
  /// non-sensibles (user_id, level, xp, streak, display_name).
  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 50}) async {
    final response = await _supabase
        .from('leaderboard_view')
        .select()
        .order('level', ascending: false)
        .order('xp', ascending: false)
        .limit(limit);

    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < response.length; i++) {
      entries.add(LeaderboardEntry.fromJson(
        Map<String, dynamic>.from(response[i] as Map),
        i + 1,
      ));
    }
    return entries;
  }
}
