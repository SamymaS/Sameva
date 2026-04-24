import 'dart:math';
import '../../data/models/item_model.dart';
import '../../data/models/quest_model.dart';
import '../../domain/services/activity_log_service.dart';
import '../../domain/services/item_factory.dart';
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
  /// Item looté aléatoirement (null = pas de drop).
  final Item? droppedItem;
  /// Cristaux reçus au level-up (0 si pas de montée).
  final int crystalsFromLevelUp;
  /// IDs des succès nouvellement débloqués.
  final List<String> newAchievements;

  const CompleteQuestResult({
    required this.rewards,
    required this.didLevelUp,
    required this.newLevel,
    this.droppedItem,
    this.crystalsFromLevelUp = 0,
    this.newAchievements = const [],
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
    final quest = _questProvider.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw StateError('Quête introuvable : $questId'),
    );
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
    final newAchievements = await _playerProvider.checkAndUnlockAchievements(
      userId,
      inventoryCount: _inventoryProvider?.items.length ?? 0,
    );

    // 4. Annuler le rappel streak (quête complétée aujourd'hui)
    await NotificationService.cancelStreakReminder();

    final levelAfter = _playerProvider.stats?.level ?? 1;
    final didLevelUp = levelAfter > levelBefore;

    // 5. Cristaux de level-up : newLevel × 2
    int crystalsFromLevelUp = 0;
    if (didLevelUp) {
      crystalsFromLevelUp = levelAfter * 2;
      await _playerProvider.addCrystals(userId, crystalsFromLevelUp);
    }

    // 6. Loot d'item aléatoire selon la difficulté (10–30% de chance)
    // Boss : drop garanti avec rareté minimum rare
    Item? droppedItem;
    if (_inventoryProvider != null) {
      final isBoss = quest.category == 'boss';
      final dropChance = isBoss ? 100 : (10 + quest.difficulty * 4);
      if (Random().nextInt(100) < dropChance) {
        final maxRarity = isBoss ? QuestRarity.legendary : _maxDropRarity(quest.difficulty);
        var rolledRarity = ItemFactory.rollGachaRarity();
        if (rolledRarity.index > maxRarity.index) rolledRarity = maxRarity;
        if (isBoss && rolledRarity.index < QuestRarity.rare.index) {
          rolledRarity = QuestRarity.rare;
        }
        droppedItem = ItemFactory.generateRandomItem(rolledRarity);
        _inventoryProvider.addItem(droppedItem);
      }
    }

    // Journal d'activité
    await ActivityLogService.addEntry(ActivityLogEntry(
      type: ActivityType.quest,
      title: quest.title,
      subtitle: '+${rewards.experience} XP · +${rewards.gold} or',
      date: now,
    ));
    if (droppedItem != null) {
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.item,
        title: 'Objet obtenu : ${droppedItem.name}',
        subtitle: droppedItem.rarity.name.toUpperCase(),
        date: now,
      ));
    }
    for (final id in newAchievements) {
      final def = PlayerStats.achievementDefinitions.firstWhere(
        (d) => d['id'] == id,
        orElse: () => {'name': id},
      );
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.achievement,
        title: 'Succès débloqué : ${def['name']}',
        date: now,
      ));
    }

    return CompleteQuestResult(
      rewards: rewards,
      didLevelUp: didLevelUp,
      newLevel: levelAfter,
      droppedItem: droppedItem,
      crystalsFromLevelUp: crystalsFromLevelUp,
      newAchievements: newAchievements,
    );
  }

  /// Rareté maximale droppable selon la difficulté de la quête.
  static QuestRarity _maxDropRarity(int difficulty) => switch (difficulty) {
        1 => QuestRarity.uncommon,
        2 => QuestRarity.rare,
        3 => QuestRarity.rare,
        4 => QuestRarity.epic,
        _ => QuestRarity.legendary,
      };
}
