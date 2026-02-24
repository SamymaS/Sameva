import '../services/quest_rewards_calculator.dart';
import '../services/notification_service.dart';
import '../../presentation/providers/quest_provider.dart';
import '../../presentation/providers/player_provider.dart';
import '../../presentation/providers/equipment_provider.dart';

/// Résultat complet de la complétion d'une quête.
class CompleteQuestResult {
  final QuestRewards rewards;
  final bool didLevelUp;
  final int newLevel;

  const CompleteQuestResult({
    required this.rewards,
    required this.didLevelUp,
    required this.newLevel,
  });
}

/// P2.1 — Use case dédié à la complétion d'une quête avec récompenses.
class CompleteQuestUseCase {
  final QuestProvider _questProvider;
  final PlayerProvider _playerProvider;
  final EquipmentProvider? _equipmentProvider;

  CompleteQuestUseCase({
    required QuestProvider questProvider,
    required PlayerProvider playerProvider,
    EquipmentProvider? equipmentProvider,
  })  : _questProvider = questProvider,
        _playerProvider = playerProvider,
        _equipmentProvider = equipmentProvider;

  Future<CompleteQuestResult> execute(String questId) async {
    final quest = _questProvider.quests.firstWhere((q) => q.id == questId);
    final now = DateTime.now();

    // Niveau avant récompenses
    final levelBefore = _playerProvider.stats?.level ?? 1;

    // 1. Marquer la quête comme complète
    await _questProvider.completeQuest(questId);

    // 2. Calculer les récompenses
    final rewards = QuestRewardsCalculator.calculateRewardsWithTiming(
      quest,
      now,
      hasStreakBonus: _playerProvider.hasStreakBonus,
      xpBonusPercent: _equipmentProvider?.xpBonusPercent ?? 0,
      goldBonusPercent: _equipmentProvider?.goldBonusPercent ?? 0,
    );

    // 3. Distribuer les récompenses
    final userId = quest.userId;
    await _playerProvider.addExperience(userId, rewards.experience);
    await _playerProvider.addGold(userId, rewards.gold);
    if (rewards.crystals > 0) {
      await _playerProvider.addCrystals(userId, rewards.crystals);
    }
    await _playerProvider.updateStreak(userId);
    await _playerProvider.incrementQuestsCompleted(userId);
    await _playerProvider.checkAndUnlockAchievements(userId);

    // 4. Annuler le rappel streak (quête complétée aujourd'hui)
    await NotificationService.cancelStreakReminder();

    final levelAfter = _playerProvider.stats?.level ?? 1;

    return CompleteQuestResult(
      rewards: rewards,
      didLevelUp: levelAfter > levelBefore,
      newLevel: levelAfter,
    );
  }
}
