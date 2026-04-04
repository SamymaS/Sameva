import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quest_model.dart';
import '../../data/models/player_stats_model.dart';
import '../../domain/services/health_regeneration_service.dart';
import '../../domain/services/item_factory.dart';
import '../../domain/services/notification_service.dart';
import '../providers/inventory_provider.dart';

// Re-export pour la compatibilité avec les fichiers qui importent PlayerStats via player_provider.dart
export '../../data/models/player_stats_model.dart';

class PlayerProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  Box get _statsBox => Hive.box('playerStats');

  PlayerStats? _stats;
  // P1.3 : userId courant pour la sync Supabase
  String? _currentUserId;

  PlayerStats? get stats => _stats;
  bool get isInitialized => _stats != null;

  // Expérience nécessaire pour monter au niveau suivant
  int experienceForLevel(int level) => (100 * (level * 1.5)).round();

  void _loadStatsFromBox() {
    try {
      final statsJson = _statsBox.get('stats');
      if (statsJson != null) {
        _stats = PlayerStats.fromJson(Map<String, dynamic>.from(statsJson as Map));
      } else {
        _stats = PlayerStats();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('PlayerProvider: erreur chargement Hive: $e');
      _stats = PlayerStats();
      notifyListeners();
    }
  }

  Future<void> _saveStats() async {
    if (_stats == null) return;
    // Sauvegarde locale (rapide)
    try {
      await _statsBox.put('stats', _stats!.toJson());
    } catch (e) {
      debugPrint('PlayerProvider: erreur sauvegarde Hive: $e');
    }
    // P1.3 : sync vers Supabase (best-effort, ne bloque pas l'UI)
    if (_currentUserId != null) {
      try {
        await _supabase.from('player_stats').upsert({
          'user_id': _currentUserId,
          ..._stats!.toSupabaseMap(),
        });
      } catch (e) {
        debugPrint('PlayerProvider: erreur sync Supabase: $e');
      }
    }
  }

  /// P1.3 : charge depuis Hive d'abord (rapide), puis tente de récupérer
  /// les stats depuis Supabase pour les synchroniser entre appareils.
  Future<void> loadPlayerStats(String userId) async {
    _currentUserId = userId;
    _loadStatsFromBox();

    try {
      final response = await _supabase
          .from('player_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final remoteStats = PlayerStats.fromSupabaseMap(
          Map<String, dynamic>.from(response),
        );
        _stats = remoteStats;
        await _statsBox.put('stats', _stats!.toJson());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PlayerProvider: erreur sync depuis Supabase: $e');
      // Stats locales déjà chargées, pas de blocage
    }

    // Régénération HP nocturne (après chargement des stats)
    if (_stats != null) {
      final regenHp = HealthRegenerationService.computeRegen(
        currentHp: _stats!.healthPoints,
        maxHp: _stats!.maxHealthPoints,
      );
      if (regenHp > 0) {
        await heal(userId, regenHp);
      }
    }
  }

  Future<void> savePlayerStats(String userId) async {
    _currentUserId = userId;
    await _saveStats();
  }

  Future<void> addExperience(String userId, int amount) async {
    if (_stats == null) return;

    int newExperience = _stats!.experience + amount;
    int newLevel = _stats!.level;

    while (newExperience >= experienceForLevel(newLevel)) {
      newExperience -= experienceForLevel(newLevel);
      newLevel++;
    }

    _stats = _stats!.copyWith(
      experience: newExperience,
      level: newLevel,
      maxHealthPoints: 100 + (newLevel - 1) * 10,
    );

    notifyListeners();
    await savePlayerStats(userId);
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

  Future<void> updateMoral(String userId, double amount) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(moral: (_stats!.moral + amount).clamp(0.0, 1.0));
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> updateStreak(String userId,
      {InventoryProvider? inventory}) async {
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
      final lastDate = DateTime(
        _stats!.lastActiveDate!.year,
        _stats!.lastActiveDate!.month,
        _stats!.lastActiveDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 0) return;
      if (difference == 1) {
        final newStreak = _stats!.streak + 1;
        _stats = _stats!.copyWith(
          streak: newStreak,
          maxStreak:
              newStreak > _stats!.maxStreak ? newStreak : _stats!.maxStreak,
          lastActiveDate: today,
        );
      } else {
        _stats = _stats!.copyWith(streak: 1, lastActiveDate: today);
      }
    }

    notifyListeners();
    await savePlayerStats(userId);

    // Vérifier les jalons de streak
    if (inventory != null) {
      await _checkStreakMilestones(userId, previousStreak, _stats!.streak,
          inventory);
    }
  }

  /// Distribue les récompenses cosmétiques aux jalons de streak.
  Future<void> _checkStreakMilestones(
    String userId,
    int oldStreak,
    int newStreak,
    InventoryProvider inventory,
  ) async {
    final milestones = <int, ({String rarity, String? title, int crystals})>{
      7:   (rarity: 'common',    title: null,                        crystals: 5),
      14:  (rarity: 'rare',      title: null,                        crystals: 0),
      30:  (rarity: 'epic',      title: 'Sorcier du Quotidien',      crystals: 0),
      100: (rarity: 'legendary', title: 'Gardien des Étoiles',       crystals: 0),
    };

    for (final entry in milestones.entries) {
      final days = entry.key;
      if (oldStreak < days && newStreak >= days) {
        final reward = entry.value;

        // Cosmétique aléatoire de la rareté
        final rarity = _rarityFromString(reward.rarity);
        final item = ItemFactory.generateRandomItem(rarity);
        inventory.addItem(item);

        // Cristaux bonus
        if (reward.crystals > 0) {
          await addCrystals(userId, reward.crystals);
        }

        // Notification locale
        try {
          await NotificationService.showStreakMilestone(days, reward.rarity);
        } catch (_) {
          // Notifications best-effort
        }

        debugPrint('Streak $days j : récompense ${reward.rarity} débloquée');
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

  bool get hasStreakBonus => _stats != null && _stats!.streak >= 7;

  Future<void> takeDamage(String userId, int amount) async {
    if (_stats == null) return;
    final newHealth = (_stats!.healthPoints - amount).clamp(0, _stats!.maxHealthPoints);
    _stats = _stats!.copyWith(healthPoints: newHealth);

    if (newHealth <= 0) {
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

  /// Incrémente le compteur pity gacha de 1.
  Future<void> incrementPity(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(pityCount: _stats!.pityCount + 1);
    notifyListeners();
    await savePlayerStats(userId);
  }

  /// Remet le compteur pity à zéro (après déclenchement).
  Future<void> resetPity(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(pityCount: 0);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> incrementQuestsCompleted(String userId) async {
    if (_stats == null) return;
    _stats = _stats!.copyWith(totalQuestsCompleted: _stats!.totalQuestsCompleted + 1);
    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<List<String>> checkAndUnlockAchievements(String userId, {int inventoryCount = 0}) async {
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
    check('quest_10', _stats!.totalQuestsCompleted >= 10);
    check('quest_50', _stats!.totalQuestsCompleted >= 50);
    check('quest_100', _stats!.totalQuestsCompleted >= 100);
    check('streak_3', _stats!.maxStreak >= 3);
    check('streak_7', _stats!.maxStreak >= 7);
    check('streak_30', _stats!.maxStreak >= 30);
    check('level_5', _stats!.level >= 5);
    check('level_10', _stats!.level >= 10);
    check('level_25', _stats!.level >= 25);
    check('rich_1000', _stats!.gold >= 1000);
    check('rich_5000', _stats!.gold >= 5000);
    check('collector_10', inventoryCount >= 10);
    check('collector_25', inventoryCount >= 25);
    check('zen_master', _stats!.moral >= 0.95);

    if (newlyUnlocked.isNotEmpty) {
      _stats = _stats!.copyWith(achievements: achievements);
      notifyListeners();
      await savePlayerStats(userId);
    }

    return newlyUnlocked;
  }
}
