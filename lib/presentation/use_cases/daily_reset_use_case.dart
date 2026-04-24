import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/services/activity_log_service.dart';
import '../../domain/services/weekly_boss_service.dart';
import '../view_models/equipment_view_model.dart';
import '../view_models/player_view_model.dart';
import '../view_models/quest_view_model.dart';

// ── Résultats retournés à la page ────────────────────────────────────────────

class DailyRewardInfo {
  final int gold;
  final int crystals;
  final int streak;

  const DailyRewardInfo({
    required this.gold,
    required this.crystals,
    required this.streak,
  });
}

class MissedPenaltyInfo {
  final int totalDamage;
  final int missedCount;

  const MissedPenaltyInfo({
    required this.totalDamage,
    required this.missedCount,
  });
}

class WeeklySummaryInfo {
  final int questsCompleted;
  final int xpEarned;
  final bool bossDefeated;
  final int streak;

  const WeeklySummaryInfo({
    required this.questsCompleted,
    required this.xpEarned,
    required this.bossDefeated,
    required this.streak,
  });
}

class DailyResetResult {
  final DailyRewardInfo? dailyReward;
  final MissedPenaltyInfo? penalties;
  final WeeklySummaryInfo? weeklySummary;
  final bool newBossGenerated;

  const DailyResetResult({
    this.dailyReward,
    this.penalties,
    this.weeklySummary,
    this.newBossGenerated = false,
  });
}

// ── Use case ─────────────────────────────────────────────────────────────────

/// Regroupe toute la logique métier de réinitialisation quotidienne/hebdomadaire.
/// Retourne un [DailyResetResult] que la page utilise pour l'affichage.
class DailyResetUseCase {
  final PlayerViewModel _player;
  final QuestViewModel _quests;
  final EquipmentViewModel _equipment;

  DailyResetUseCase({
    required PlayerViewModel player,
    required QuestViewModel quests,
    required EquipmentViewModel equipment,
  })  : _player = player,
        _quests = quests,
        _equipment = equipment;

  Future<DailyResetResult> execute(String userId) async {
    final settings = Hive.box('settings');

    await _applyEquipmentHpBonus(userId, settings);
    final penalties = await _applyMissedPenalties(userId, settings);
    final weeklySummary = await _checkWeeklySummary(userId, settings);
    final dailyReward = await _checkDailyReward(userId, settings);
    final newBoss = await _checkWeeklyBoss(userId);

    return DailyResetResult(
      dailyReward: dailyReward,
      penalties: penalties,
      weeklySummary: weeklySummary,
      newBossGenerated: newBoss,
    );
  }

  Future<void> _applyEquipmentHpBonus(String userId, Box settings) async {
    final expected = _equipment.hpBonus;
    final stored = settings.get('last_equipment_hp_bonus', defaultValue: 0) as int;
    if (expected == stored) return;
    await _player.adjustMaxHp(userId, expected - stored);
    await settings.put('last_equipment_hp_bonus', expected);
  }

  Future<MissedPenaltyInfo?> _applyMissedPenalties(
      String userId, Box settings) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if ((settings.get('last_penalty_date') as String?) == today) return null;

    final missed = _quests.getMissedQuests();
    await settings.put('last_penalty_date', today);
    if (missed.isEmpty) return null;

    int totalDamage = 0;
    for (final q in missed) {
      final dmg = 10 * q.difficulty;
      totalDamage += dmg;
      await ActivityLogService.addEntry(ActivityLogEntry(
        type: ActivityType.quest,
        title: 'Quête manquée : ${q.title}',
        subtitle: '-$dmg HP · -10% moral',
        date: DateTime.now(),
      ));
      await _quests.deleteQuest(q.id!);
    }

    await _player.takeDamage(userId, totalDamage);
    await _player.updateMoral(userId, -(missed.length * 0.1));

    return MissedPenaltyInfo(
      totalDamage: totalDamage,
      missedCount: missed.length,
    );
  }

  Future<DailyRewardInfo?> _checkDailyReward(
      String userId, Box settings) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if ((settings.get('last_login_date') as String?) == today) return null;
    await settings.put('last_login_date', today);

    final streak = _player.stats?.streak ?? 0;
    final streakBonus = streak ~/ 7;
    final gold = 50 + streakBonus * 10;
    final crystals = 5 + streakBonus * 2;

    await _player.addGold(userId, gold);
    await _player.addCrystals(userId, crystals);

    return DailyRewardInfo(gold: gold, crystals: crystals, streak: streak);
  }

  Future<WeeklySummaryInfo?> _checkWeeklySummary(
      String userId, Box settings) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${monday.year}_${monday.month}_${monday.day}';

    if (settings.get('last_weekly_summary') == weekKey) return null;
    if (now.weekday < 2) return null;

    await settings.put('last_weekly_summary', weekKey);

    final prevMonday = monday.subtract(const Duration(days: 7));
    final prevSunday = monday.subtract(const Duration(seconds: 1));

    final weekQuests = _quests.completedQuests.where((q) =>
        q.completedAt != null &&
        q.completedAt!.isAfter(prevMonday) &&
        q.completedAt!.isBefore(prevSunday)).toList();

    final log = ActivityLogService.getLog();
    int weekXp = 0;
    for (final entry in log) {
      if (entry.type == ActivityType.quest &&
          entry.date.isAfter(prevMonday) &&
          entry.date.isBefore(prevSunday) &&
          entry.subtitle != null) {
        final match = RegExp(r'\+(\d+) XP').firstMatch(entry.subtitle!);
        if (match != null) weekXp += int.tryParse(match.group(1)!) ?? 0;
      }
    }

    final bossDefeated = weekQuests.any((q) => q.category == 'boss');
    if (bossDefeated) await _player.addCrystals(userId, 15);

    return WeeklySummaryInfo(
      questsCompleted: weekQuests.length,
      xpEarned: weekXp,
      bossDefeated: bossDefeated,
      streak: _player.stats?.streak ?? 0,
    );
  }

  Future<bool> _checkWeeklyBoss(String userId) async {
    if (WeeklyBossService.hasGeneratedThisWeek()) return false;
    final hasBoss = _quests.activeQuests.any((q) => q.category == 'boss');
    if (hasBoss) {
      await WeeklyBossService.markGenerated();
      return false;
    }
    final boss = WeeklyBossService.buildBossQuest(userId);
    await _quests.addQuest(boss);
    await WeeklyBossService.markGenerated();
    return true;
  }
}
