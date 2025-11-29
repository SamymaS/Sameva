import '../core/providers/player_provider.dart';
import '../core/providers/quest_provider.dart';
import 'bonus_malus_service.dart';

/// Service pour gérer la régénération des PV au fil du temps
class HealthRegenerationService {
  /// Calcule la régénération automatique des PV basée sur l'activité
  /// Régénère plus vite si le joueur complète des quêtes régulièrement
  static int calculateRegenerationAmount({
    required PlayerStats stats,
    required List<Quest> completedQuestsToday,
    required List<Quest> activeQuestsToday,
  }) {
    // Régénération de base : 1% des PV max par heure
    int baseRegeneration = (stats.maxHealthPoints * 0.01).round();

    // Bonus si le joueur a complété des quêtes aujourd'hui
    if (completedQuestsToday.isNotEmpty) {
      final completionRate = completedQuestsToday.length / 
          (activeQuestsToday.isEmpty ? 1 : activeQuestsToday.length);
      baseRegeneration += (baseRegeneration * completionRate * 0.5).round();
    }

    // Bonus de streak
    if (stats.streak >= 7) {
      baseRegeneration += (baseRegeneration * 0.2).round(); // +20% pour streak 7+
    }

    // Malus si le moral est bas
    if (stats.moral < 0.5) {
      baseRegeneration = (baseRegeneration * 0.5).round(); // -50% si moral bas
    }

    return baseRegeneration;
  }

  /// Vérifie si le joueur doit perdre des PV à cause de l'inactivité
  static int calculateInactivityDamage({
    required PlayerStats stats,
    required List<Quest> missedQuests,
  }) {
    if (missedQuests.isEmpty) {
      return 0;
    }

    // Perte de PV basée sur le nombre de quêtes manquées
    final damagePerMissedQuest = (stats.maxHealthPoints * 0.02).round(); // 2% par quête manquée
    final totalDamage = damagePerMissedQuest * missedQuests.length;

    // Limiter à 20% des PV max
    return totalDamage.clamp(0, (stats.maxHealthPoints * 0.2).round());
  }

  /// Applique les effets de régénération/dégâts sur les PV
  static Future<void> applyHealthEffects({
    required String userId,
    required PlayerProvider playerProvider,
    required QuestProvider questProvider,
  }) async {
    final stats = playerProvider.stats;
    if (stats == null) return;

    final completedQuestsToday = questProvider.getCompletedQuestsToday();
    final activeQuestsToday = questProvider.getActiveQuestsToday();
    final missedQuests = questProvider.getMissedQuests();

    // Régénération
    final regeneration = calculateRegenerationAmount(
      stats: stats,
      completedQuestsToday: completedQuestsToday,
      activeQuestsToday: activeQuestsToday,
    );

    if (regeneration > 0 && stats.healthPoints < stats.maxHealthPoints) {
      await playerProvider.heal(userId, regeneration);
    }

    // Dégâts d'inactivité (seulement si le joueur a manqué des quêtes importantes)
    if (missedQuests.isNotEmpty) {
      final damage = calculateInactivityDamage(
        stats: stats,
        missedQuests: missedQuests,
      );

      if (damage > 0) {
        await playerProvider.takeDamage(userId, damage);
      }
    }
  }

  /// Vérifie et applique les effets de santé basés sur le moral
  static Future<void> applyMoralEffects({
    required String userId,
    required PlayerProvider playerProvider,
  }) async {
    final stats = playerProvider.stats;
    if (stats == null) return;

    // Si le moral est très bas (< 0.2), le joueur perd des PV progressivement
    if (stats.moral < 0.2) {
      final damage = (stats.maxHealthPoints * 0.05).round(); // 5% des PV max
      await playerProvider.takeDamage(userId, damage);
    }
    // Si le moral est élevé (> 0.8), le joueur régénère un peu
    else if (stats.moral > 0.8 && stats.healthPoints < stats.maxHealthPoints) {
      final heal = (stats.maxHealthPoints * 0.02).round(); // 2% des PV max
      await playerProvider.heal(userId, heal);
    }
  }
}



