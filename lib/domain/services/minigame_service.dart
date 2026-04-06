import 'package:hive/hive.dart';

/// Gère la limite quotidienne de parties de mini-jeux.
/// Chaque jeu est identifié par une [gameKey] unique.
/// Maximum [maxDailyPlays] parties par jeu par jour.
class MinigameService {
  static const int maxDailyPlays = 3;

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  /// Nombre de parties jouées aujourd'hui pour [gameKey].
  static int playsToday(Box settings, String gameKey) {
    final savedDate = settings.get('${gameKey}_date') as String?;
    if (savedDate != _today()) return 0;
    return settings.get('${gameKey}_plays', defaultValue: 0) as int;
  }

  /// Parties restantes aujourd'hui.
  static int remainingPlays(Box settings, String gameKey) =>
      (maxDailyPlays - playsToday(settings, gameKey)).clamp(0, maxDailyPlays);

  /// Vérifie si le joueur peut encore jouer aujourd'hui.
  static bool canPlay(Box settings, String gameKey) =>
      playsToday(settings, gameKey) < maxDailyPlays;

  /// Enregistre une partie jouée. Appeler avant de lancer le jeu.
  static Future<void> recordPlay(Box settings, String gameKey) async {
    final plays = playsToday(settings, gameKey);
    await settings.put('${gameKey}_date', _today());
    await settings.put('${gameKey}_plays', plays + 1);
    // Incrémenter le compteur total toutes sessions confondues
    final total = settings.get('total_minigames_played', defaultValue: 0) as int;
    await settings.put('total_minigames_played', total + 1);
  }

  /// Total de parties jouées depuis l'installation.
  static int totalPlayed(Box settings) =>
      settings.get('total_minigames_played', defaultValue: 0) as int;
}
