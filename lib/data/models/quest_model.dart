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

  String toSupabaseString() {
    switch (this) {
      case QuestRarity.common:
        return 'common';
      case QuestRarity.uncommon:
        return 'uncommon';
      case QuestRarity.rare:
        return 'rare';
      case QuestRarity.epic:
        return 'epic';
      case QuestRarity.legendary:
        return 'legendary';
      case QuestRarity.mythic:
        return 'mythic';
    }
  }

  static QuestRarity fromSupabaseString(String value) {
    switch (value) {
      case 'common':
        return QuestRarity.common;
      case 'uncommon':
        return QuestRarity.uncommon;
      case 'rare':
        return QuestRarity.rare;
      case 'epic':
        return QuestRarity.epic;
      case 'legendary':
        return QuestRarity.legendary;
      case 'mythic':
        return QuestRarity.mythic;
      default:
        return QuestRarity.common;
    }
  }
}

enum QuestFrequency {
  oneOff, // Correspond à 'one_off' dans Supabase
  daily,
  weekly,
  monthly;

  String toSupabaseString() {
    switch (this) {
      case QuestFrequency.oneOff:
        return 'one_off';
      case QuestFrequency.daily:
        return 'daily';
      case QuestFrequency.weekly:
        return 'weekly';
      case QuestFrequency.monthly:
        return 'monthly';
    }
  }

  static QuestFrequency fromSupabaseString(String value) {
    switch (value) {
      case 'one_off':
        return QuestFrequency.oneOff;
      case 'daily':
        return QuestFrequency.daily;
      case 'weekly':
        return QuestFrequency.weekly;
      case 'monthly':
        return QuestFrequency.monthly;
      default:
        return QuestFrequency.oneOff;
    }
  }
}

enum QuestStatus {
  active,
  completed,
  failed,
  archived;

  String toSupabaseString() {
    switch (this) {
      case QuestStatus.active:
        return 'active';
      case QuestStatus.completed:
        return 'completed';
      case QuestStatus.failed:
        return 'failed';
      case QuestStatus.archived:
        return 'archived';
    }
  }

  static QuestStatus fromSupabaseString(String value) {
    switch (value) {
      case 'active':
        return QuestStatus.active;
      case 'completed':
        return QuestStatus.completed;
      case 'failed':
        return QuestStatus.failed;
      case 'archived':
        return QuestStatus.archived;
      default:
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

  String toSupabaseString() {
    switch (this) {
      case ValidationType.manual:
        return 'manual';
      case ValidationType.photo:
        return 'photo';
      case ValidationType.timer:
        return 'timer';
      case ValidationType.geolocation:
        return 'geolocation';
    }
  }

  static ValidationType fromSupabaseString(String value) {
    switch (value) {
      case 'manual':
        return ValidationType.manual;
      case 'photo':
        return ValidationType.photo;
      case 'timer':
        return ValidationType.timer;
      case 'geolocation':
        return ValidationType.geolocation;
      default:
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
  final bool isCompleted;
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
    this.isCompleted = false,
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
      'is_completed': isCompleted,
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
      isCompleted: map['is_completed'] as bool? ?? false,
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
    bool? isCompleted,
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
      isCompleted: isCompleted ?? this.isCompleted,
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

