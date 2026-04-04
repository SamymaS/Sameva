import '../../domain/services/quest_rewards_calculator.dart';
import '../../domain/services/notification_service.dart';
import '../view_models/quest_view_model.dart';
import '../view_models/player_view_model.dart';
import '../view_models/equipment_view_model.dart';
import '../view_models/inventory_view_model.dart';

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
  final QuestViewModel _questProvider;
  final PlayerViewModel _playerProvider;
  final EquipmentViewModel? _equipmentProvider;
  final InventoryViewModel? _inventoryProvider;

  CompleteQuestUseCase({
    required QuestViewModel questProvider,
    required PlayerViewModel playerProvider,
    EquipmentViewModel? equipmentProvider,
    InventoryViewModel? inventoryProvider,
  })  : _questProvider = questProvider,
        _playerProvider = playerProvider,
        _equipmentProvider = equipmentProvider,
        _inventoryProvider = inventoryProvider;

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
    await _playerProvider.updateStreak(userId, inventory: _inventoryProvider);
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
