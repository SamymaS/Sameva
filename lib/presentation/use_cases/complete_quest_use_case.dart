import '../../data/models/item_model.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/game_api.dart';
import '../../domain/services/activity_log_service.dart';
import '../../domain/services/item_factory.dart';
import '../../domain/services/notification_service.dart';
import '../view_models/quest_view_model.dart';
import '../view_models/player_view_model.dart';
import '../view_models/inventory_view_model.dart';

/// Résultat complet de la complétion d'une quête, tel que calculé par le
/// serveur (Sprint 1).
class CompleteQuestResult {
  /// Récompenses accordées par le serveur.
  final QuestRewardResult rewards;

  /// Objet obtenu (généré localement depuis la rareté tirée par le serveur ;
  /// transitoire jusqu'au Sprint 3). null = pas de butin.
  final Item? droppedItem;

  /// Objets des paliers de flamme (même logique transitoire).
  final List<Item> milestoneItems;

  /// IDs des succès nouvellement débloqués (locaux, cosmétiques).
  final List<String> newAchievements;

  const CompleteQuestResult({
    required this.rewards,
    this.droppedItem,
    this.milestoneItems = const [],
    this.newAchievements = const [],
  });

  bool get didLevelUp => rewards.didLevelUp;
  int get newLevel => rewards.levelAfter;
  int get crystalsFromLevelUp => rewards.levelUpCrystals;
}

/// Complétion d'une quête.
///
/// Sprint 1 : aucune récompense n'est calculée ici. Deux chemins :
/// - [execute] : validation déclarative, le serveur applique la formule
///   (`complete_quest`) ;
/// - [applyOracleVerdict] : la quête a déjà été close et récompensée par
///   l'Oracle côté serveur, on se contente de refléter le résultat.
class CompleteQuestUseCase {
  final QuestViewModel _questProvider;
  final PlayerViewModel _playerProvider;
  final InventoryViewModel? _inventoryProvider;

  CompleteQuestUseCase({
    required QuestViewModel questProvider,
    required PlayerViewModel playerProvider,
    InventoryViewModel? inventoryProvider,
  })  : _questProvider = questProvider,
        _playerProvider = playerProvider,
        _inventoryProvider = inventoryProvider;

  /// Validation déclarative. Lève [GameApiException] si le serveur refuse
  /// (`preuve_requise`, `quete_trop_recente`, `quete_deja_cloturee`...).
  Future<CompleteQuestResult> execute(Quest quest) async {
    final questId = quest.id;
    if (questId == null) {
      throw const GameApiException('quete_introuvable');
    }
    final rewards = await _playerProvider.completeQuest(questId);
    return _afterServerCompletion(quest, rewards);
  }

  /// La quête a été validée par l'Oracle : le serveur l'a déjà close et
  /// récompensée. [rewards] vient de la réponse de l'Edge Function.
  Future<CompleteQuestResult> applyOracleVerdict(Quest quest, QuestRewardResult rewards) async {
    await _playerProvider.refresh();
    return _afterServerCompletion(quest, rewards);
  }

  Future<CompleteQuestResult> _afterServerCompletion(Quest quest, QuestRewardResult rewards) async {
    final now = DateTime.now();
    if (quest.id != null) {
      await _questProvider.markCompletedFromServer(quest.id!, completedAt: now);
    }

    try {
      await NotificationService.cancelStreakReminder();
      await NotificationService.rescheduleStreakReminder();
    } catch (_) {
      // Les notifications ne bloquent jamais la complétion.
    }

    // Objets : matérialisation locale des raretés tirées par le serveur.
    Item? dropped;
    final milestoneItems = <Item>[];
    final inventory = _inventoryProvider;
    if (inventory != null) {
      if (rewards.dropRarity != null) {
        dropped = ItemFactory.generateRandomItem(rewards.dropRarity!);
        inventory.addItem(dropped);
      }
      for (final m in rewards.streakMilestones) {
        if (m.itemRarity == null) continue;
        final item = ItemFactory.generateRandomItem(m.itemRarity!);
        if (inventory.addItem(item)) milestoneItems.add(item);
      }
    }

    final newAchievements = await _playerProvider.checkAndUnlockAchievements(
      quest.userId,
      inventoryCount: inventory?.items.length ?? 0,
    );

    // Journal d'activité.
    await ActivityLogService.addEntry(ActivityLogEntry(
      type: ActivityType.quest,
      title: quest.title,
      subtitle: '+${rewards.xp} XP · +${rewards.gold} or'
          '${rewards.seals > 0 ? ' · +${rewards.seals} Sceau${rewards.seals > 1 ? 'x' : ''}' : ''}',
      date: now,
    ));
    if (rewards.didLevelUp) {
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.levelUp,
        title: 'Niveau ${rewards.levelAfter} atteint !',
        subtitle: '+${rewards.levelUpCrystals} cristaux',
        date: now,
      ));
    }
    for (final m in rewards.streakMilestones) {
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.streak,
        title: 'Flamme de ${m.days} jours !',
        subtitle: '+${m.crystals} cristaux',
        date: now,
      ));
    }
    if (dropped != null) {
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.item,
        title: 'Objet obtenu : ${dropped.name}',
        subtitle: dropped.rarity.name.toUpperCase(),
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
      droppedItem: dropped,
      milestoneItems: milestoneItems,
      newAchievements: newAchievements,
    );
  }
}
