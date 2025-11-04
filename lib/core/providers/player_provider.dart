import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PlayerStats {
  final int level;
  final int experience;
  final int gold;
  final int healthPoints;
  final int maxHealthPoints;
  final double credibilityScore;
  final Map<String, int> achievements;

  PlayerStats({
    this.level = 1,
    this.experience = 0,
    this.gold = 0,
    this.healthPoints = 100,
    this.maxHealthPoints = 100,
    this.credibilityScore = 1.0,
    Map<String, int>? achievements,
  }) : achievements = achievements ?? {};

  Map<String, dynamic> toJson() => {
    'level': level,
    'experience': experience,
    'gold': gold,
    'healthPoints': healthPoints,
    'maxHealthPoints': maxHealthPoints,
    'credibilityScore': credibilityScore,
    'achievements': achievements,
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    level: json['level'] as int? ?? 1,
    experience: json['experience'] as int? ?? 0,
    gold: json['gold'] as int? ?? 0,
    healthPoints: json['healthPoints'] as int? ?? 100,
    maxHealthPoints: json['maxHealthPoints'] as int? ?? 100,
    credibilityScore: (json['credibilityScore'] as num?)?.toDouble() ?? 1.0,
    achievements: json['achievements'] != null 
        ? Map<String, int>.from(json['achievements'] as Map)
        : {},
  );

  PlayerStats copyWith({
    int? level,
    int? experience,
    int? gold,
    int? healthPoints,
    int? maxHealthPoints,
    double? credibilityScore,
    Map<String, int>? achievements,
  }) => PlayerStats(
    level: level ?? this.level,
    experience: experience ?? this.experience,
    gold: gold ?? this.gold,
    healthPoints: healthPoints ?? this.healthPoints,
    maxHealthPoints: maxHealthPoints ?? this.maxHealthPoints,
    credibilityScore: credibilityScore ?? this.credibilityScore,
    achievements: achievements ?? this.achievements,
  );
}

class PlayerProvider with ChangeNotifier {
  Box get _statsBox => Hive.box('playerStats');
  PlayerStats? _stats;

  PlayerStats? get stats => _stats;
  bool get isInitialized => _stats != null;

  // Expérience nécessaire pour chaque niveau
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
      print('Erreur lors du chargement des stats: $e');
      _stats = PlayerStats();
      notifyListeners();
    }
  }

  Future<void> _saveStatsToBox() async {
    if (_stats == null) return;
    try {
      await _statsBox.put('stats', _stats!.toJson());
    } catch (e) {
      print('Erreur lors de la sauvegarde des stats: $e');
    }
  }

  Future<void> loadPlayerStats(String userId) async {
    // Pas besoin de userId pour le stockage local
    _loadStatsFromBox();
  }

  Future<void> savePlayerStats(String userId) async {
    await _saveStatsToBox();
  }

  Future<void> addExperience(String userId, int amount) async {
    if (_stats == null) return;

    int newExperience = _stats!.experience + amount;
    int newLevel = _stats!.level;

    // Vérifier si le joueur monte de niveau
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

    _stats = _stats!.copyWith(
      gold: _stats!.gold + amount,
    );

    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> takeDamage(String userId, int amount) async {
    if (_stats == null) return;

    int newHealth = (_stats!.healthPoints - amount).clamp(0, _stats!.maxHealthPoints);
    
    _stats = _stats!.copyWith(
      healthPoints: newHealth,
    );

    // Si les points de vie tombent à zéro, réinitialiser le joueur
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

    _stats = _stats!.copyWith(
      credibilityScore: newScore.clamp(0.0, 1.0),
    );

    notifyListeners();
    await savePlayerStats(userId);
  }

  Future<void> resetPlayer(String userId) async {
    _stats = PlayerStats(
      level: 1,
      experience: 0,
      gold: (_stats?.gold ?? 0) ~/ 2, // Perte de la moitié de l'or
      healthPoints: 100,
      maxHealthPoints: 100,
      credibilityScore: (_stats?.credibilityScore ?? 1.0) * 0.9, // Pénalité de crédibilité
      achievements: _stats?.achievements ?? {},
    );

    notifyListeners();
    await savePlayerStats(userId);
  }
} 