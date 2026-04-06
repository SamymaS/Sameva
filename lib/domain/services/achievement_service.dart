import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../ui/theme/app_colors.dart';

/// Définition d'un achievement.
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Service de gestion des achievements.
/// Stocke les achievements débloqués dans Hive (box 'settings', clé 'achievements').
class AchievementService {
  static const String _hiveKey = 'achievements';

  static const List<Achievement> all = [
    // ── Quêtes ────────────────────────────────────────────────────────────
    Achievement(
      id: 'first_quest',
      name: 'Première quête',
      description: 'Completez votre première quête.',
      icon: Icons.flag_outlined,
      color: AppColors.rarityCommon,
    ),
    Achievement(
      id: 'quest_10',
      name: 'Aventurier',
      description: '10 quêtes complétées.',
      icon: Icons.military_tech_outlined,
      color: AppColors.rarityUncommon,
    ),
    Achievement(
      id: 'quest_50',
      name: 'Vétéran',
      description: '50 quêtes complétées.',
      icon: Icons.workspace_premium_outlined,
      color: AppColors.rarityRare,
    ),
    Achievement(
      id: 'quest_100',
      name: 'Légendaire',
      description: '100 quêtes complétées.',
      icon: Icons.emoji_events_outlined,
      color: AppColors.rarityLegendary,
    ),

    // ── Streak ────────────────────────────────────────────────────────────
    Achievement(
      id: 'streak_3',
      name: 'Série naissante',
      description: '3 jours de série consécutifs.',
      icon: Icons.local_fire_department_outlined,
      color: AppColors.warning,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Série enflammée',
      description: '7 jours de série consécutifs.',
      icon: Icons.local_fire_department,
      color: AppColors.coralRare,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Série légendaire',
      description: '30 jours de série consécutifs.',
      icon: Icons.whatshot,
      color: AppColors.rarityMythic,
    ),

    // ── Niveau ────────────────────────────────────────────────────────────
    Achievement(
      id: 'level_5',
      name: 'Apprenti',
      description: 'Atteindre le niveau 5.',
      icon: Icons.arrow_upward_outlined,
      color: AppColors.rarityCommon,
    ),
    Achievement(
      id: 'level_10',
      name: 'Initié',
      description: 'Atteindre le niveau 10.',
      icon: Icons.trending_up_outlined,
      color: AppColors.rarityUncommon,
    ),
    Achievement(
      id: 'level_25',
      name: 'Maître',
      description: 'Atteindre le niveau 25.',
      icon: Icons.auto_awesome_outlined,
      color: AppColors.rarityEpic,
    ),

    // ── Or ────────────────────────────────────────────────────────────────
    Achievement(
      id: 'gold_500',
      name: 'Premier trésor',
      description: 'Posséder 500 pièces d\'or.',
      icon: Icons.monetization_on_outlined,
      color: AppColors.gold,
    ),
    Achievement(
      id: 'gold_5000',
      name: 'Riche marchand',
      description: 'Posséder 5 000 pièces d\'or.',
      icon: Icons.monetization_on,
      color: AppColors.gold,
    ),

    // ── Boss ──────────────────────────────────────────────────────────────
    Achievement(
      id: 'boss_first',
      name: 'Tueur de boss',
      description: 'Vaincre votre premier boss hebdomadaire.',
      icon: Icons.security_outlined,
      color: AppColors.rarityEpic,
    ),

    // ── Mini-jeux ─────────────────────────────────────────────────────────
    Achievement(
      id: 'minigame_first',
      name: 'Premier jeu',
      description: 'Jouer à un mini-jeu pour la première fois.',
      icon: Icons.videogame_asset_outlined,
      color: AppColors.primaryTurquoise,
    ),
    Achievement(
      id: 'minigame_10',
      name: 'Joueur assidu',
      description: 'Jouer à 10 mini-jeux.',
      icon: Icons.videogame_asset,
      color: AppColors.rarityRare,
    ),

    // ── Invocation ────────────────────────────────────────────────────────
    Achievement(
      id: 'gacha_first',
      name: 'Première invocation',
      description: 'Invoquer un objet pour la première fois.',
      icon: Icons.auto_fix_high_outlined,
      color: AppColors.secondaryViolet,
    ),
    Achievement(
      id: 'gacha_multi',
      name: 'Grand invocateur',
      description: 'Réaliser une invocation ×10.',
      icon: Icons.auto_fix_high,
      color: AppColors.rarityEpic,
    ),
  ];

  // ── Lecture / écriture Hive ──────────────────────────────────────────────

  /// Retourne les achievements débloqués : Map<id, unlockedAt ISO string>.
  static Map<String, String> getUnlocked() {
    final raw = Hive.box('settings').get(_hiveKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw as String) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, String> unlocked) async {
    await Hive.box('settings').put(_hiveKey, jsonEncode(unlocked));
  }

  /// Débloque un achievement par ID si pas déjà débloqué.
  /// Retourne true si nouvellement débloqué.
  static Future<bool> unlock(String id) async {
    final unlocked = getUnlocked();
    if (unlocked.containsKey(id)) return false;
    unlocked[id] = DateTime.now().toIso8601String();
    await _save(unlocked);
    return true;
  }

  // ── Vérification globale ─────────────────────────────────────────────────

  /// Vérifie toutes les conditions et débloque les achievements mérités.
  /// Retourne la liste des IDs nouvellement débloqués.
  static Future<List<String>> checkAll({
    required int level,
    required int totalQuests,
    required int streak,
    required int gold,
    required int minigamesPlayed,
    required bool bossDefeated,
    required bool hasGachaFirst,
    required bool hasGachaMulti,
  }) async {
    final newlyUnlocked = <String>[];

    Future<void> tryUnlock(String id, bool condition) async {
      if (condition && await unlock(id)) newlyUnlocked.add(id);
    }

    // Quêtes
    await tryUnlock('first_quest', totalQuests >= 1);
    await tryUnlock('quest_10',    totalQuests >= 10);
    await tryUnlock('quest_50',    totalQuests >= 50);
    await tryUnlock('quest_100',   totalQuests >= 100);

    // Streak
    await tryUnlock('streak_3',  streak >= 3);
    await tryUnlock('streak_7',  streak >= 7);
    await tryUnlock('streak_30', streak >= 30);

    // Niveau
    await tryUnlock('level_5',  level >= 5);
    await tryUnlock('level_10', level >= 10);
    await tryUnlock('level_25', level >= 25);

    // Or
    await tryUnlock('gold_500',  gold >= 500);
    await tryUnlock('gold_5000', gold >= 5000);

    // Boss
    await tryUnlock('boss_first', bossDefeated);

    // Mini-jeux
    await tryUnlock('minigame_first', minigamesPlayed >= 1);
    await tryUnlock('minigame_10',    minigamesPlayed >= 10);

    // Invocation
    await tryUnlock('gacha_first', hasGachaFirst);
    await tryUnlock('gacha_multi', hasGachaMulti);

    return newlyUnlocked;
  }
}
