import '../core/providers/quest_provider.dart';
import '../core/providers/player_provider.dart';

/// Service pour calculer les bonus/malus basés sur les quêtes et l'activité
class BonusMalusService {
  /// Calcule le bonus/malus basé sur les quêtes complétées aujourd'hui
  static double calculateDailyQuestBonus(
    List<Quest> completedQuestsToday,
    List<Quest> activeQuestsToday,
  ) {
    if (activeQuestsToday.isEmpty) {
      return 1.0; // Pas de quêtes actives, pas de bonus
    }

    final completionRate = completedQuestsToday.length / activeQuestsToday.length;
    
    // Bonus progressif selon le taux de complétion
    if (completionRate >= 1.0) {
      return 1.5; // +50% si toutes les quêtes sont complétées
    } else if (completionRate >= 0.8) {
      return 1.3; // +30% si 80%+ complétées
    } else if (completionRate >= 0.5) {
      return 1.1; // +10% si 50%+ complétées
    } else if (completionRate >= 0.25) {
      return 1.0; // Pas de bonus
    } else {
      return 0.9; // -10% si moins de 25% complétées
    }
  }

  /// Calcule le malus pour les quêtes non complétées
  static double calculateMissedQuestMalus(
    List<Quest> missedQuests,
    int totalActiveQuests,
  ) {
    if (totalActiveQuests == 0) {
      return 1.0;
    }

    final missedRate = missedQuests.length / totalActiveQuests;
    
    // Malus progressif selon le taux de quêtes manquées
    if (missedRate >= 0.5) {
      return 0.7; // -30% si 50%+ quêtes manquées
    } else if (missedRate >= 0.25) {
      return 0.85; // -15% si 25%+ quêtes manquées
    } else {
      return 1.0; // Pas de malus
    }
  }

  /// Calcule le bonus de streak (jours consécutifs)
  static double calculateStreakBonus(int streak) {
    if (streak >= 30) {
      return 1.4; // +40% pour 30+ jours
    } else if (streak >= 14) {
      return 1.3; // +30% pour 14+ jours
    } else if (streak >= 7) {
      return 1.2; // +20% pour 7+ jours
    } else if (streak >= 3) {
      return 1.1; // +10% pour 3+ jours
    } else {
      return 1.0; // Pas de bonus
    }
  }

  /// Calcule le malus pour inactivité (pas de quêtes complétées depuis X jours)
  static double calculateInactivityMalus(DateTime? lastActiveDate) {
    if (lastActiveDate == null) {
      return 1.0;
    }

    final daysSinceLastActivity = DateTime.now().difference(lastActiveDate).inDays;
    
    if (daysSinceLastActivity >= 7) {
      return 0.6; // -40% après 7 jours d'inactivité
    } else if (daysSinceLastActivity >= 3) {
      return 0.75; // -25% après 3 jours d'inactivité
    } else if (daysSinceLastActivity >= 1) {
      return 0.9; // -10% après 1 jour d'inactivité
    } else {
      return 1.0; // Pas de malus
    }
  }

  /// Calcule le bonus/malus total combiné
  static double calculateTotalBonusMalus({
    required List<Quest> completedQuestsToday,
    required List<Quest> activeQuestsToday,
    required List<Quest> missedQuests,
    required int streak,
    required DateTime? lastActiveDate,
  }) {
    double multiplier = 1.0;

    // Bonus de complétion quotidienne
    multiplier *= calculateDailyQuestBonus(completedQuestsToday, activeQuestsToday);

    // Malus de quêtes manquées
    multiplier *= calculateMissedQuestMalus(missedQuests, activeQuestsToday.length);

    // Bonus de streak
    multiplier *= calculateStreakBonus(streak);

    // Malus d'inactivité
    multiplier *= calculateInactivityMalus(lastActiveDate);

    // Limiter entre 0.5 et 2.0
    return multiplier.clamp(0.5, 2.0);
  }

  /// Applique les effets de bonus/malus sur les PV
  static int calculateHealthModifier(double bonusMalus, int baseHealth) {
    if (bonusMalus < 1.0) {
      // Malus : réduire les PV max
      final reduction = (1.0 - bonusMalus) * 0.2; // Max 20% de réduction
      return (baseHealth * (1.0 - reduction)).round();
    } else {
      // Bonus : augmenter les PV max
      final increase = (bonusMalus - 1.0) * 0.1; // Max 10% d'augmentation
      return (baseHealth * (1.0 + increase)).round();
    }
  }

  /// Applique les effets de bonus/malus sur l'expérience
  static int calculateExperienceModifier(double bonusMalus, int baseExperience) {
    return (baseExperience * bonusMalus).round();
  }

  /// Applique les effets de bonus/malus sur l'or
  static int calculateGoldModifier(double bonusMalus, int baseGold) {
    return (baseGold * bonusMalus).round();
  }
}



