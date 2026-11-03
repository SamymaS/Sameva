import 'package:hive_flutter/hive_flutter.dart';
import '../../data/repositories/game_api.dart';
import '../../domain/services/activity_log_service.dart';
import '../view_models/player_view_model.dart';
import '../view_models/quest_view_model.dart';

// ── Résultats retournés à la page ────────────────────────────────────────────

class DailyRewardInfo {
  final int gold;
  final int seals;
  final int energy;
  final int streak;

  const DailyRewardInfo({
    required this.gold,
    required this.seals,
    required this.energy,
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
  final int streak;

  const WeeklySummaryInfo({
    required this.questsCompleted,
    required this.xpEarned,
    required this.streak,
  });
}

class DailyResetResult {
  final DailyRewardInfo? dailyReward;
  final MissedPenaltyInfo? penalties;
  final WeeklySummaryInfo? weeklySummary;
  final bool streakLost;

  const DailyResetResult({
    this.dailyReward,
    this.penalties,
    this.weeklySummary,
    this.streakLost = false,
  });
}

// ── Use case ─────────────────────────────────────────────────────────────────

/// Règles quotidiennes (Sprint 1) : tout est calculé par le serveur
/// (`claim_daily`, idempotent). Le client ne supprime plus de quêtes, ne crée
/// plus de boss et ne crédite plus rien : il affiche le résumé renvoyé.
/// Le résumé hebdomadaire reste un simple affichage local, sans récompense.
class DailyResetUseCase {
  final PlayerViewModel _player;
  final QuestViewModel _quests;

  DailyResetUseCase({
    required PlayerViewModel player,
    required QuestViewModel quests,
  })  : _player = player,
        _quests = quests;

  Future<DailyResetResult> execute(String userId) async {
    final daily = await _player.claimDaily();

    MissedPenaltyInfo? penalties;
    if (daily.missedQuests.isNotEmpty) {
      // Les quêtes manquées sont passées « échouées » côté serveur : on relit.
      await _quests.loadQuests(userId);
      for (final q in daily.missedQuests) {
        await ActivityLogService.addEntry(ActivityLogEntry(
          type: ActivityType.quest,
          title: 'Quête manquée : ${q.title}',
          subtitle: 'Quête échouée',
          date: DateTime.now(),
        ));
      }
      penalties = MissedPenaltyInfo(
        totalDamage: daily.hpLost,
        missedCount: daily.missedQuests.length,
      );
    }

    final dailyReward = daily.firstToday
        ? DailyRewardInfo(
            gold: daily.loginGold,
            seals: daily.loginSeals,
            energy: daily.energyGranted,
            streak: _player.stats?.streak ?? 0,
          )
        : null;

    return DailyResetResult(
      dailyReward: dailyReward,
      penalties: penalties,
      weeklySummary: _weeklySummary(Hive.box('settings')),
      streakLost: daily.streakLost,
    );
  }

  /// Résumé de la semaine passée, affiché une fois par semaine à partir du
  /// mardi. Purement informatif (aucune récompense côté client).
  WeeklySummaryInfo? _weeklySummary(Box settings) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = '${monday.year}_${monday.month}_${monday.day}';

    if (settings.get('last_weekly_summary') == weekKey) return null;
    if (now.weekday < 2) return null;
    settings.put('last_weekly_summary', weekKey);

    final prevMonday = DateTime(monday.year, monday.month, monday.day)
        .subtract(const Duration(days: 7));
    final thisMonday = DateTime(monday.year, monday.month, monday.day);

    final weekQuests = _quests.completedQuests.where((q) =>
        q.completedAt != null &&
        q.completedAt!.isAfter(prevMonday) &&
        q.completedAt!.isBefore(thisMonday)).toList();

    int weekXp = 0;
    for (final entry in ActivityLogService.getLog()) {
      if (entry.type == ActivityType.quest &&
          entry.date.isAfter(prevMonday) &&
          entry.date.isBefore(thisMonday) &&
          entry.subtitle != null) {
        final match = RegExp(r'\+(\d+) XP').firstMatch(entry.subtitle!);
        if (match != null) weekXp += int.tryParse(match.group(1)!) ?? 0;
      }
    }

    // Rien à raconter (nouveau joueur, semaine vide) : pas de résumé à zéro.
    if (weekQuests.isEmpty && weekXp == 0) return null;

    return WeeklySummaryInfo(
      questsCompleted: weekQuests.length,
      xpEarned: weekXp,
      streak: _player.stats?.streak ?? 0,
    );
  }
}

/// Message lisible en cas d'échec de `claim_daily` (réseau).
String dailyErrorMessage(Object e) =>
    e is GameApiException ? e.userMessage : 'Connexion impossible. Vérifie ton réseau.';
