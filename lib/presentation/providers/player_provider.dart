import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerStats {
  final int level;
  final int experience;
  final int gold;
  final int crystals;
  final int healthPoints;
  final int maxHealthPoints;
  final double credibilityScore;
  final double moral;
  final int streak;
  final int maxStreak;
  final DateTime? lastActiveDate;
  final Map<String, int> achievements;
  final int totalQuestsCompleted;

  PlayerStats({
    this.level = 1,
    this.experience = 0,
    this.gold = 0,
    this.crystals = 0,
    this.healthPoints = 100,
    this.maxHealthPoints = 100,
    this.credibilityScore = 1.0,
    this.moral = 1.0,
    this.streak = 0,
    this.maxStreak = 0,
    DateTime? lastActiveDate,
    Map<String, int>? achievements,
    this.totalQuestsCompleted = 0,
  })  : lastActiveDate = lastActiveDate,
        achievements = achievements ?? {};

  Map<String, dynamic> toJson() => {
        'level': level,
        'experience': experience,
        'gold': gold,
        'crystals': crystals,
        'healthPoints': healthPoints,
        'maxHealthPoints': maxHealthPoints,
        'credibilityScore': credibilityScore,
        'moral': moral,
        'streak': streak,
        'maxStreak': maxStreak,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'achievements': achievements,
        'totalQuestsCompleted': totalQuestsCompleted,
      };

  // P1.3 : sérialisation pour Supabase (snake_case)
  Map<String, dynamic> toSupabaseMap() => {
        'level': level,
        'experience': experience,
        'gold': gold,
        'crystals': crystals,
        'health_points': healthPoints,
        'max_health_points': maxHealthPoints,
        'credibility_score': credibilityScore,
        'moral': moral,
        'streak': streak,
        'max_streak': maxStreak,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'achievements': achievements,
        'total_quests_completed': totalQuestsCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        level: json['level'] as int? ?? 1,
        experience: json['experience'] as int? ?? 0,
        gold: json['gold'] as int? ?? 0,
        crystals: json['crystals'] as int? ?? 0,
        healthPoints: json['healthPoints'] as int? ?? 100,
        maxHealthPoints: json['maxHealthPoints'] as int? ?? 100,
        credibilityScore: (json['credibilityScore'] as num?)?.toDouble() ?? 1.0,
        moral: (json['moral'] as num?)?.toDouble() ?? 1.0,
        streak: json['streak'] as int? ?? 0,
        maxStreak: json['maxStreak'] as int? ?? 0,
        lastActiveDate: json['lastActiveDate'] != null
            ? DateTime.parse(json['lastActiveDate'] as String)
            : null,
        achievements: json['achievements'] != null
            ? Map<String, int>.from(json['achievements'] as Map)
            : {},
        totalQuestsCompleted: json['totalQuestsCompleted'] as int? ?? 0,
      );

  // P1.3 : lecture depuis Supabase (snake_case)
  factory PlayerStats.fromSupabaseMap(Map<String, dynamic> map) => PlayerStats(
        level: map['level'] as int? ?? 1,
        experience: map['experience'] as int? ?? 0,
        gold: map['gold'] as int? ?? 0,
        crystals: map['crystals'] as int? ?? 0,
        healthPoints: map['health_points'] as int? ?? 100,
        maxHealthPoints: map['max_health_points'] as int? ?? 100,
        credibilityScore: (map['credibility_score'] as num?)?.toDouble() ?? 1.0,
        moral: (map['moral'] as num?)?.toDouble() ?? 1.0,
        streak: map['streak'] as int? ?? 0,
        maxStreak: map['max_streak'] as int? ?? 0,
        lastActiveDate: map['last_active_date'] != null
            ? DateTime.parse(map['last_active_date'] as String)
            : null,
        achievements: map['achievements'] != null
            ? Map<String, int>.from(map['achievements'] as Map)
            : {},
        totalQuestsCompleted: map['total_quests_completed'] as int? ?? 0,
      );

  PlayerStats copyWith({
    int? level,
    int? experience,
    int? gold,
    int? crystals,
    int? healthPoints,
    int? maxHealthPoints,
    double? credibilityScore,
    double? moral,
    int? streak,
    int? maxStreak,
    DateTime? lastActiveDate,
    Map<String, int>? achievements,
    int? totalQuestsCompleted,
  }) =>
      PlayerStats(
        level: level ?? this.level,
        experience: experience ?? this.experience,
        gold: gold ?? this.gold,
        crystals: crystals ?? this.crystals,
        healthPoints: healthPoints ?? this.healthPoints,
        maxHealthPoints: maxHealthPoints ?? this.maxHealthPoints,
        credibilityScore: credibilityScore ?? this.credibilityScore,
        moral: moral ?? this.moral,
        streak: streak ?? this.streak,
        maxStreak: maxStreak ?? this.maxStreak,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        achievements: achievements ?? this.achievements,
        totalQuestsCompleted: totalQuestsCompleted ?? this.totalQuestsCompleted,
      );
}

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

  Future<void> updateStreak(String userId) async {
    if (_stats == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
          maxStreak: newStreak > _stats!.maxStreak ? newStreak : _stats!.maxStreak,
          lastActiveDate: today,
        );
      } else {
        _stats = _stats!.copyWith(streak: 1, lastActiveDate: today);
      }
    }

    notifyListeners();
    await savePlayerStats(userId);
  }

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

  static const List<Map<String, String>> achievementDefinitions = [
    {'id': 'first_quest', 'name': 'Premiers Pas', 'description': 'Compléter sa première quête', 'icon': 'star'},
    {'id': 'quest_10', 'name': 'Aventurier', 'description': 'Compléter 10 quêtes', 'icon': 'military_tech'},
    {'id': 'quest_50', 'name': 'Héros', 'description': 'Compléter 50 quêtes', 'icon': 'emoji_events'},
    {'id': 'quest_100', 'name': 'Légende', 'description': 'Compléter 100 quêtes', 'icon': 'workspace_premium'},
    {'id': 'streak_3', 'name': 'Régulier', 'description': '3 jours consécutifs', 'icon': 'local_fire_department'},
    {'id': 'streak_7', 'name': 'Persévérant', 'description': '7 jours consécutifs', 'icon': 'whatshot'},
    {'id': 'streak_30', 'name': 'Inarrêtable', 'description': '30 jours consécutifs', 'icon': 'bolt'},
    {'id': 'level_5', 'name': 'Apprenti', 'description': 'Atteindre le niveau 5', 'icon': 'trending_up'},
    {'id': 'level_10', 'name': 'Expert', 'description': 'Atteindre le niveau 10', 'icon': 'school'},
    {'id': 'level_25', 'name': 'Maître', 'description': 'Atteindre le niveau 25', 'icon': 'psychology'},
    {'id': 'rich_1000', 'name': 'Fortuné', 'description': "Accumuler 1000 pièces d'or", 'icon': 'paid'},
    {'id': 'rich_5000', 'name': 'Magnat', 'description': "Accumuler 5000 pièces d'or", 'icon': 'diamond'},
    {'id': 'collector_10', 'name': 'Collectionneur', 'description': 'Posséder 10 objets', 'icon': 'inventory_2'},
    {'id': 'collector_25', 'name': 'Thésauriseur', 'description': 'Posséder 25 objets', 'icon': 'warehouse'},
    {'id': 'zen_master', 'name': 'Maître Zen', 'description': 'Moral au maximum', 'icon': 'self_improvement'},
  ];
}
