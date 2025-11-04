import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../utils/quest_rewards_calculator.dart';

enum QuestRarity {
  common,
  uncommon,
  rare,
  veryRare,
  epic,
  legendary,
  mythic
}

enum QuestFrequency {
  once,
  daily,
  weekly,
  monthly
}

class Quest {
  final String id;
  final String title;
  final String? description;
  final Duration estimatedDuration;
  final QuestFrequency frequency;
  final int difficulty;
  final String category;
  final QuestRarity rarity;
  final List<String> subQuests;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  Quest({
    String? id,
    required this.title,
    this.description,
    required this.estimatedDuration,
    required this.frequency,
    required this.difficulty,
    required this.category,
    required this.rarity,
    List<String>? subQuests,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : id = id ?? const Uuid().v4(),
       subQuests = subQuests ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'estimatedDuration': estimatedDuration.inMinutes,
    'frequency': frequency.toString(),
    'difficulty': difficulty,
    'category': category,
    'rarity': rarity.toString(),
    'subQuests': subQuests,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
    frequency: QuestFrequency.values.firstWhere(
      (e) => e.toString() == json['frequency'],
    ),
    difficulty: json['difficulty'] as int,
    category: json['category'] as String,
    rarity: QuestRarity.values.firstWhere(
      (e) => e.toString() == json['rarity'],
    ),
    subQuests: (json['subQuests'] as List).cast<String>(),
    isCompleted: json['isCompleted'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}

class QuestProvider with ChangeNotifier {
  Box get _questsBox => Hive.box('quests');
  
  List<Quest> _quests = [];
  
  List<Quest> get quests => _quests;
  List<Quest> get activeQuests => _quests.where((q) => !q.isCompleted).toList();
  List<Quest> get completedQuests => _quests.where((q) => q.isCompleted).toList();
  
  void _loadQuestsFromBox() {
    try {
      final questsList = _questsBox.get('quests', defaultValue: <Map>[]);
      _quests = (questsList as List)
          .map((json) => Quest.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des quêtes: $e');
      _quests = [];
    }
  }
  
  Future<void> _saveQuestsToBox() async {
    try {
      final questsJson = _quests.map((q) => q.toJson()).toList();
      await _questsBox.put('quests', questsJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde des quêtes: $e');
    }
  }

  Future<void> loadQuests(String userId) async {
    // Pas besoin de userId pour le stockage local
    _loadQuestsFromBox();
  }

  Future<void> addQuest(String userId, Quest quest) async {
    try {
      _quests.add(quest);
      await _saveQuestsToBox();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuest(String userId, Quest quest) async {
    try {
      final index = _quests.indexWhere((q) => q.id == quest.id);
      if (index != -1) {
        _quests[index] = quest;
        await _saveQuestsToBox();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuest(String userId, String questId) async {
    try {
      _quests.removeWhere((q) => q.id == questId);
      await _saveQuestsToBox();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeQuest(String userId, String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      final updatedQuest = Quest(
        id: quest.id,
        title: quest.title,
        description: quest.description,
        estimatedDuration: quest.estimatedDuration,
        frequency: quest.frequency,
        difficulty: quest.difficulty,
        category: quest.category,
        rarity: quest.rarity,
        subQuests: quest.subQuests,
        isCompleted: true,
        createdAt: quest.createdAt,
        completedAt: DateTime.now(),
      );

      await updateQuest(userId, updatedQuest);
    } catch (e) {
      rethrow;
    }
  }

  /// Retourne les récompenses calculées pour une quête
  /// Utilise QuestRewardsCalculator pour calculer les récompenses
  QuestRewards calculateRewards(Quest quest, DateTime completedAt, {bool hasStreakBonus = false}) {
    return QuestRewardsCalculator.calculateRewardsWithTiming(
      quest,
      completedAt,
      hasStreakBonus: hasStreakBonus,
    );
  }
} 