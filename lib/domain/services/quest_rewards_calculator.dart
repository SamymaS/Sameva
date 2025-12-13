import '../../presentation/providers/quest_provider.dart';

/// Classe représentant les récompenses d'une quête
class QuestRewards {
  final int experience;
  final int gold;
  final int crystals;
  final double? moralPenalty; // Si négatif, c'est une pénalité
  final String bonusType; // 'normal', 'on_time', 'early', 'late', 'failed'
  final double multiplier;

  QuestRewards({
    required this.experience,
    required this.gold,
    this.crystals = 0,
    this.moralPenalty,
    this.bonusType = 'normal',
    this.multiplier = 1.0,
  });

  bool get isPositive => experience >= 0 && gold >= 0;
  bool get hasBonus => multiplier > 1.0;
  bool get hasPenalty => multiplier < 1.0 || moralPenalty != null;
}

/// Classe utilitaire pour calculer les récompenses d'une quête
class QuestRewardsCalculator {
  /// Calcule les récompenses de base selon la difficulté
  /// Formule: XP = 10 × difficulté, Or = 25 × difficulté
  static QuestRewards calculateBaseRewards(int difficulty) {
    final baseXP = 10 * difficulty;
    final baseGold = 25 * difficulty;
    final crystals = difficulty > 3 ? 1 : 0;

    return QuestRewards(
      experience: baseXP,
      gold: baseGold,
      crystals: crystals,
    );
  }

  /// Calcule les récompenses avec bonus/malus selon la ponctualité
  /// 
  /// Bonus de ponctualité : +10% si terminée à temps
  /// Grand bonus : +25% si terminée en avance
  /// Malus de retard : -20% si terminée après l'échéance
  static QuestRewards calculateRewardsWithTiming(
    Quest quest,
    DateTime completedAt, {
    bool hasStreakBonus = false,
  }) {
    final baseRewards = calculateBaseRewards(quest.difficulty);
    
    // Calculer l'échéance estimée
    final estimatedDeadline = quest.createdAt.add(quest.estimatedDuration);
    
    // Calculer le temps écoulé
    final timeDifference = completedAt.difference(quest.createdAt);
    final estimatedTime = quest.estimatedDuration;
    
    double multiplier = 1.0;
    String bonusType = 'normal';

    // Vérifier si terminée en avance (plus de 20% plus tôt)
    if (timeDifference < estimatedTime * 0.8) {
      multiplier = 1.25; // Grand bonus
      bonusType = 'early';
    }
    // Vérifier si terminée à temps (dans les 20% de l'échéance)
    else if (!completedAt.isAfter(estimatedDeadline)) {
      multiplier = 1.1; // Bonus de ponctualité
      bonusType = 'on_time';
    }
    // Vérifier si terminée en retard
    else if (completedAt.isAfter(estimatedDeadline)) {
      multiplier = 0.8; // Malus de retard
      bonusType = 'late';
    }

    // Bonus de streak (7 jours consécutifs)
    if (hasStreakBonus) {
      multiplier += 0.1;
    }

    return QuestRewards(
      experience: (baseRewards.experience * multiplier).round(),
      gold: (baseRewards.gold * multiplier).round(),
      crystals: baseRewards.crystals,
      bonusType: bonusType,
      multiplier: multiplier,
    );
  }

  /// Calcule les malus pour une quête échouée ou abandonnée
  /// Malus: -50% moral, -10% XP
  static QuestRewards calculateFailurePenalty(Quest quest, int currentXP) {
    final xpPenalty = (currentXP * 0.1).round();
    
    return QuestRewards(
      experience: -xpPenalty,
      gold: 0,
      crystals: 0,
      moralPenalty: -0.5,
      bonusType: 'failed',
    );
  }
}
