import '../services/quest_rewards_calculator.dart';
import '../../presentation/providers/quest_provider.dart';
import '../../presentation/providers/player_provider.dart';
import '../../presentation/providers/equipment_provider.dart';

/// P2.1 — Use case dédié à la complétion d'une quête avec récompenses.
///
/// Responsabilité unique : orchestrer QuestProvider et PlayerProvider
/// sans que l'un connaisse l'autre. La logique de récompense est centralisée
/// ici, hors des providers.
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

  /// Complète la quête [questId] et distribue les récompenses calculées.
  ///
  /// Retourne les [QuestRewards] pour affichage dans l'UI.
  Future<QuestRewards> execute(String questId) async {
    final quest = _questProvider.quests.firstWhere((q) => q.id == questId);
    final now = DateTime.now();

    // 1. Marquer la quête comme complète
    await _questProvider.completeQuest(questId);

    // 2. Calculer les récompenses avec bonus timing, streak et équipement
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

    return rewards;
  }
}
