/// Entrée du classement global.
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int level;
  final int experience;
  final int streak;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.level,
    required this.experience,
    required this.streak,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    // La vue leaderboard_view expose : user_id, level, xp, streak, display_name.
    // xp est l'alias SQL de player_stats.experience.
    final displayName =
        (json['display_name'] as String?)?.isNotEmpty == true
            ? json['display_name'] as String
            : 'Aventurier';

    return LeaderboardEntry(
      userId: json['user_id'] as String? ?? '',
      displayName: displayName,
      level: json['level'] as int? ?? 1,
      experience: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      rank: rank,
    );
  }
}
