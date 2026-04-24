import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import '../../data/models/player_stats_model.dart';
import '../../data/repositories/player_repository.dart';
import '../../domain/services/activity_log_service.dart';
import '../../domain/services/health_regeneration_service.dart';
import '../../domain/services/item_factory.dart';
import '../../domain/services/notification_service.dart';
import './inventory_view_model.dart';

// Re-export pour la compatibilité des imports existants
export '../../data/models/player_stats_model.dart';

/// ViewModel pour les statistiques joueur (état global).
/// Délègue la persistance à PlayerRepository — logique métier ici.
class PlayerViewModel with ChangeNotifier {
  final PlayerRepository _repo;

  PlayerStats? _stats;
  String? _currentUserId;

  PlayerViewModel(this._repo);

  PlayerStats? get stats => _stats;
  bool get isInitialized => _stats != null;
  bool get hasStreakBonus => _stats != null && _stats!.streak >= 7;

  int experienceForLevel(int level) => (100 * (level * 1.5)).round();

  // ── Chargement ────────────────────────────────────────────────────────────

  Future<void> loadPlayerStats(String userId) async {
    _currentUserId = userId;

    // Offline-first : Hive immédiat
    _stats = _repo.loadLocalStats();
    notifyListeners();

    // Sync distante (best-effort)
    try {
      final remote = await _repo.fetchRemoteStats(userId);
      if (remote != null) {
        _stats = remote;
        await _repo.saveLocalStats(remote);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PlayerViewModel: erreur sync Supabase: $e');
    }

    // Vérification streak expiré (si absence >= 2 jours depuis dernière activité)
    if (_stats != null && _stats!.lastActiveDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final last = DateTime(
        _stats!.lastActiveDate!.year,
        _stats!.lastActiveDate!.month,
        _stats!.lastActiveDate!.day,
      );
      if (today.difference(last).inDays >= 2) {
        _stats = _stats!.copyWith(streak: 0);
        await _repo.saveLocalStats(_stats!);
        notifyListeners();
      }
    }

    // Régénération HP nocturne
    if (_stats != null) {
      final regen = HealthRegenerationService.computeRegen(
        currentHp: _stats!.healthPoints,
        maxHp: _stats!.maxHealthPoints,
      );
      if (regen > 0) await heal(userId, regen);
    }
  }

  Future<void> savePlayerStats(String userId) async {
    _currentUserId = userId;
    await _persistStats();
  }

  Future<void> _persistStats() async {
    if (_stats == null) return;
    await _repo.saveLocalStats(_stats!);
    if (_currentUserId != null) {
      await _repo.syncToSupabase(_currentUserId!, _stats!);
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> addExperience(String userId, int amount) async {
    if (_stats == null) return;

    int xp = _stats!.experience + amount;
    int level = _stats!.level;
    int levelsGained = 0;

    while (xp >= experienceForLevel(level)) {
      xp -= experienceForLevel(level);
      level++;
      levelsGained++;
    }

    // +10 HP max par niveau gagné (incrémental, préserve les bonus équipement)
    final newMax = _stats!.maxHealthPoints + levelsGained * 10;
    _stats = _stats!.copyWith(
      experience: xp,
      level: level,
      maxHealthPoints: newMax,
    );
    notifyListeners();
    await savePlayerStats(userId);

    if (levelsGained > 0) {
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.levelUp,
        title: 'Niveau $level atteint !',
        subtitle: 'Montée de niveau +$levelsGained',
        date: DateTime.now(),
      ));
    }
  }

  Future<void> addGold(String userId, int amount) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(gold: _stats!.gold + amount);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> addCrystals(String userId, int amount) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(crystals: _stats!.crystals + amount);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> spendCrystals(String userId, int amount) async {
    if (_stats == null || _stats!.crystals < amount) return;
    _stats = _stats!.copyWith(crystals: _stats!.crystals - amount);
    notifyListeners();
    await savePlayerStats(userId);
  }

  /// Modifie les HP max (delta positif = bonus équipement, négatif = retrait).
  /// Les HP courants sont plafonnés au nouveau max si nécessaire.
  Future<void> adjustMaxHp(String userId, int delta) async {
    if (_stats == null) return;
    final newMax = (_stats!.maxHealthPoints + delta).clamp(10, 99999);
    final newHp = _stats!.healthPoints.clamp(0, newMax);
    _stats = _stats!.copyWith(maxHealthPoints: newMax, healthPoints: newHp);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> updateMoral(String userId, double amount) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(moral: (_stats!.moral + amount).clamp(0.0, 1.0));
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> updateStreak(String userId, {InventoryViewModel? inventory}) async {
    if (_stats == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final previousStreak = _stats!.streak;

    if (_stats!.lastActiveDate == null) {
      _stats = _stats!.copyWith(
        streak: 1,
        maxStreak: _stats!.maxStreak < 1 ? 1 : _stats!.maxStreak,
        lastActiveDate: today,
      );
    } else {
      final last = DateTime(
        _stats!.lastActiveDate!.year,
        _stats!.lastActiveDate!.month,
        _stats!.lastActiveDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 0) return;
      if (diff == 1) {
        final newStreak = _stats!.streak + 1;
        _stats = _stats!.copyWith(
          streak: newStreak,
          maxStreak: newStreak > _stats!.maxStreak ? newStreak : _stats!.maxStreak,
          lastActiveDate: today,
        );
      } else {
        _stats = _stats!.copyWith(streak: 1, lastActiveDate: today);
      }
    }

    notifyListeners();
    await savePlayerStats(userId);

    try {
      await NotificationService.rescheduleStreakReminder();
    } catch (e) {
      debugPrint('PlayerViewModel: erreur reschedule streak: $e');
    }

    if (inventory != null) {
      await _checkStreakMilestones(userId, previousStreak, _stats!.streak, inventory);
    }
  }

  Future<void> _checkStreakMilestones(
    String userId,
    int oldStreak,
    int newStreak,
    InventoryViewModel inventory,
  ) async {
    final milestones = <int, ({String rarity, int crystals})>{
      7:   (rarity: 'common',    crystals: 5),
      14:  (rarity: 'rare',      crystals: 10),
      30:  (rarity: 'epic',      crystals: 25),
      100: (rarity: 'legendary', crystals: 100),
    };

    for (final entry in milestones.entries) {
      if (oldStreak < entry.key && newStreak >= entry.key) {
        final reward = entry.value;
        inventory.addItem(ItemFactory.generateRandomItem(_rarityFromString(reward.rarity)));
        if (reward.crystals > 0) await addCrystals(userId, reward.crystals);
        try {
          await NotificationService.showStreakMilestone(entry.key, reward.rarity);
        } catch (e) {
          debugPrint('PlayerViewModel: erreur notification streak milestone: $e');
        }
        await ActivityLogService.addEntry(ActivityLogEntry(
          type: ActivityType.streak,
          title: 'Streak ${entry.key} jours atteint !',
          subtitle: '+${reward.crystals} cristaux · objet ${reward.rarity}',
          date: DateTime.now(),
        ));
        debugPrint('Streak ${entry.key} j : récompense ${reward.rarity} débloquée');
      }
    }
  }

  static QuestRarity _rarityFromString(String r) => switch (r) {
        'uncommon'  => QuestRarity.uncommon,
        'rare'      => QuestRarity.rare,
        'epic'      => QuestRarity.epic,
        'legendary' => QuestRarity.legendary,
        'mythic'    => QuestRarity.mythic,
        _           => QuestRarity.common,
      };

  Future<void> takeDamage(String userId, int amount) async {
    if (_stats == null) return;
    final hp = (_stats!.healthPoints - amount).clamp(0, _stats!.maxHealthPoints);
    _stats = _stats!.copyWith(healthPoints: hp);
    if (hp <= 0) {
      await resetPlayer(userId);
    } else {
      notifyListeners();
      await savePlayerStats(userId);
    }
  }

  Future<void> heal(String userId, int amount) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(
      healthPoints: (_stats!.healthPoints + amount).clamp(0, _stats!.maxHealthPoints),
    );
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> updateCredibilityScore(String userId, double newScore) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(credibilityScore: newScore.clamp(0.0, 1.0));
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> resetPlayer(String userId) async {
    _stats = PlayerStats(
      level: 1,
      experience: 0,
      gold: (_stats?.gold ?? 0) ~/ 2,
      healthPoints: 100,
      maxHealthPoints: 100,
      credibilityScore: (_stats?.credibilityScore ?? 1.0) * 0.9,
      achievements: _stats?.achievements ?? {},
      maxStreak: _stats?.maxStreak ?? 0,
      totalQuestsCompleted: _stats?.totalQuestsCompleted ?? 0,
    );
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> incrementPity(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(pityCount: _stats!.pityCount + 1);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> resetPity(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(pityCount: 0);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> incrementQuestsCompleted(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(
        totalQuestsCompleted: _stats!.totalQuestsCompleted + 1);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<List<String>> checkAndUnlockAchievements(String userId,
      {int inventoryCount = 0}) async {
    if (_stats == null) return [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final achievements = Map<String, int>.from(_stats!.achievements);
    final newlyUnlocked = <String>[];

    void check(String id, bool condition) {
      if (condition && !achievements.containsKey(id)) {
        achievements[id] = now;
        newlyUnlocked.add(id);
      }
    }

    check('first_quest', _stats!.totalQuestsCompleted >= 1);
    check('quest_10',    _stats!.totalQuestsCompleted >= 10);
    check('quest_50',    _stats!.totalQuestsCompleted >= 50);
    check('quest_100',   _stats!.totalQuestsCompleted >= 100);
    check('streak_3',    _stats!.maxStreak >= 3);
    check('streak_7',    _stats!.maxStreak >= 7);
    check('streak_30',   _stats!.maxStreak >= 30);
    check('level_5',     _stats!.level >= 5);
    check('level_10',    _stats!.level >= 10);
    check('level_25',    _stats!.level >= 25);
    check('rich_1000',   _stats!.gold >= 1000);
    check('rich_5000',   _stats!.gold >= 5000);
    check('collector_10', inventoryCount >= 10);
    check('collector_25', inventoryCount >= 25);
    check('zen_master',  _stats!.moral >= 0.95);

    if (newlyUnlocked.isNotEmpty) {
      _stats = _stats!.copyWith(achievements: achievements);
      notifyListeners();
      await savePlayerStats(userId);
    }

    return newlyUnlocked;
  }
}
