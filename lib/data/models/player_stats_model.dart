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

  const PlayerStats({
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
    this.lastActiveDate,
    this.achievements = const {},
    this.totalQuestsCompleted = 0,
  });

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

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        level: json['level'] as int? ?? 1,
        experience: json['experience'] as int? ?? 0,
        gold: json['gold'] as int? ?? 0,
        crystals: json['crystals'] as int? ?? 0,
        healthPoints: json['healthPoints'] as int? ?? 100,
        maxHealthPoints: json['maxHealthPoints'] as int? ?? 100,
        credibilityScore:
            (json['credibilityScore'] as num?)?.toDouble() ?? 1.0,
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
        totalQuestsCompleted:
            totalQuestsCompleted ?? this.totalQuestsCompleted,
      );

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
    {'id': 'rich_1000', 'name': 'Fortuné', 'description': 'Accumuler 1000 pièces d\'or', 'icon': 'paid'},
    {'id': 'rich_5000', 'name': 'Magnat', 'description': 'Accumuler 5000 pièces d\'or', 'icon': 'diamond'},
    {'id': 'collector_10', 'name': 'Collectionneur', 'description': 'Posséder 10 objets', 'icon': 'inventory_2'},
    {'id': 'collector_25', 'name': 'Thésauriseur', 'description': 'Posséder 25 objets', 'icon': 'warehouse'},
    {'id': 'zen_master', 'name': 'Maître Zen', 'description': 'Moral au maximum', 'icon': 'self_improvement'},
  ];
}
