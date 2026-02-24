// ============================================
// ENUMS (Alignés avec le schéma Supabase)
// ============================================

enum QuestRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic;

  // P3 : .name correspond exactement aux valeurs Supabase
  String toSupabaseString() => name;

  static QuestRarity fromSupabaseString(String value) {
    try {
      return QuestRarity.values.byName(value);
    } catch (_) {
      return QuestRarity.common;
    }
  }
}

enum QuestFrequency {
  oneOff, // Correspond à 'one_off' dans Supabase (seul cas avec snake_case)
  daily,
  weekly,
  monthly;

  // P3 : .name pour tous sauf oneOff qui a un underscore dans Supabase
  String toSupabaseString() => switch (this) {
    QuestFrequency.oneOff => 'one_off',
    _ => name,
  };

  static QuestFrequency fromSupabaseString(String value) => switch (value) {
    'one_off' => QuestFrequency.oneOff,
    _ => QuestFrequency.values.byName(value),
  };
}

enum QuestStatus {
  active,
  completed,
  failed,
  archived;

  // P3 : .name correspond exactement aux valeurs Supabase
  String toSupabaseString() => name;

  static QuestStatus fromSupabaseString(String value) {
    try {
      return QuestStatus.values.byName(value);
    } catch (_) {
      return QuestStatus.active;
    }
  }
}

// Type de validation (pour anti-triche)
enum ValidationType {
  manual,
  photo,
  timer,
  geolocation;

  // P3 : .name correspond exactement aux valeurs Supabase
  String toSupabaseString() => name;

  static ValidationType fromSupabaseString(String value) {
    try {
      return ValidationType.values.byName(value);
    } catch (_) {
      return ValidationType.manual;
    }
  }
}

// ============================================
// MODÈLE QUEST (Pour Supabase)
// ============================================

class Quest {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final int estimatedDurationMinutes;
  final QuestFrequency frequency;
  final int difficulty;
  final String category;
  final QuestRarity rarity;
  final List<String> subQuests;
  // P2.3 : isCompleted supprimé — dérivé de status == QuestStatus.completed
  final QuestStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deadline;
  final DateTime? updatedAt;

  // Champs de validation et récompenses
  final ValidationType validationType;
  final int? xpReward;
  final int? goldReward;
  final String? proofData; // Données de preuve (photo, géolocalisation, etc.)

  // P2.3 : getter dérivé, pas de champ redondant
  bool get isCompleted => status == QuestStatus.completed;

  Quest({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.estimatedDurationMinutes,
    required this.frequency,
    required this.difficulty,
    required this.category,
    required this.rarity,
    List<String>? subQuests,
    required this.status,
    DateTime? createdAt,
    this.completedAt,
    this.deadline,
    DateTime? updatedAt,
    ValidationType? validationType,
    this.xpReward,
    this.goldReward,
    this.proofData,
  })  : subQuests = subQuests ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        validationType = validationType ?? ValidationType.manual;

  // Conversion vers Map pour Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'frequency': frequency.toSupabaseString(),
      'difficulty': difficulty,
      'category': category,
      'rarity': rarity.toSupabaseString(),
      'sub_quests': subQuests,
      // P2.3 : is_completed dérivé de status (compatible avec la colonne DB)
      'is_completed': status == QuestStatus.completed,
      'status': status.toSupabaseString(),
      'validation_type': validationType.toSupabaseString(),
      'xp_reward': xpReward,
      'gold_reward': goldReward,
      if (proofData != null) 'proof_data': proofData,
      'created_at': createdAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Création depuis une réponse Supabase
  factory Quest.fromSupabaseMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      estimatedDurationMinutes: map['estimated_duration_minutes'] as int? ?? 0,
      frequency: QuestFrequency.fromSupabaseString(map['frequency'] as String),
      difficulty: map['difficulty'] as int,
      category: map['category'] as String,
      rarity: QuestRarity.fromSupabaseString(map['rarity'] as String),
      subQuests: (map['sub_quests'] as List<dynamic>?)?.cast<String>() ?? [],
      // P2.3 : status est la source de vérité, is_completed ignoré à la lecture
      status: QuestStatus.fromSupabaseString(map['status'] as String? ?? 'active'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      validationType: ValidationType.fromSupabaseString(
        map['validation_type'] as String? ?? 'manual',
      ),
      xpReward: map['xp_reward'] as int?,
      goldReward: map['gold_reward'] as int?,
      proofData: map['proof_data'] as String?,
    );
  }

  // Copie avec modifications
  Quest copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? estimatedDurationMinutes,
    QuestFrequency? frequency,
    int? difficulty,
    String? category,
    QuestRarity? rarity,
    List<String>? subQuests,
    QuestStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deadline,
    DateTime? updatedAt,
    ValidationType? validationType,
    int? xpReward,
    int? goldReward,
    String? proofData,
  }) {
    return Quest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      subQuests: subQuests ?? this.subQuests,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      updatedAt: updatedAt ?? this.updatedAt,
      validationType: validationType ?? this.validationType,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      proofData: proofData ?? this.proofData,
    );
  }
}
