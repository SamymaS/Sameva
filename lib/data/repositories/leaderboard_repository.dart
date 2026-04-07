import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry_model.dart';

/// Récupère le classement global depuis Supabase.
class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository(this._supabase);

  /// Retourne les [limit] meilleurs joueurs triés par niveau puis XP.
  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 50}) async {
    final response = await _supabase
        .from('player_stats')
        .select('user_id, level, experience, streak, users(display_name, username)')
        .order('level', ascending: false)
        .order('experience', ascending: false)
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
