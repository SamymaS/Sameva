import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/quest_rewards_calculator.dart';

/// ViewModel pour les quêtes (état global partagé entre pages).
/// Délègue la persistance à QuestRepository.
class QuestViewModel with ChangeNotifier {
  final QuestRepository _repo;

  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _error;

  QuestViewModel(this._repo);

  List<Quest> get quests => _quests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Quest> get activeQuests => _quests.where((q) => q.status == QuestStatus.active).toList();
  List<Quest> get completedQuests => _quests.where((q) => q.status == QuestStatus.completed).toList();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadQuests(String userId) async {
    if (userId.isEmpty) {
      _quests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quests = await _repo.loadQuests(userId);
      // Replanifier les notifications deadline pour les quêtes actives
      final now = DateTime.now();
      for (final q in _quests) {
        if (q.status == QuestStatus.active &&
            q.deadline != null &&
            q.deadline!.isAfter(now)) {
          await NotificationService.scheduleQuestDeadlineReminder(q);
        }
      }
    } catch (e) {
      debugPrint('QuestViewModel: erreur chargement: $e');
      _error = 'Impossible de charger les quêtes. Vérifiez votre connexion.';
      _quests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuest(Quest quest) async {
    try {
      final newQuest = await _repo.addQuest(quest);
      _quests.insert(0, newQuest);
      notifyListeners();
      if (newQuest.deadline != null) {
        await NotificationService.scheduleQuestDeadlineReminder(newQuest);
      }
    } catch (e) {
      debugPrint('QuestViewModel: erreur création: $e');
      rethrow;
    }
  }

  Future<void> updateQuest(Quest quest) async {
    try {
      final updated = await _repo.updateQuest(quest);
      final index = _quests.indexWhere((q) => q.id == quest.id);
      if (index != -1) {
        _quests[index] = updated;
        notifyListeners();
      }
      if (updated.id != null) {
        await NotificationService.cancelQuestDeadlineReminder(updated.id!);
        if (updated.deadline != null && updated.deadline!.isAfter(DateTime.now())) {
          await NotificationService.scheduleQuestDeadlineReminder(updated);
        }
      }
    } catch (e) {
      debugPrint('QuestViewModel: erreur mise à jour: $e');
      rethrow;
    }
  }

  Future<void> deleteQuest(String questId) async {
    try {
      await _repo.deleteQuest(questId);
      _quests.removeWhere((q) => q.id == questId);
      notifyListeners();
      await NotificationService.cancelQuestDeadlineReminder(questId);
    } catch (e) {
      debugPrint('QuestViewModel: erreur suppression: $e');
      rethrow;
    }
  }

  Future<void> completeQuest(String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      final updated = await _repo.completeQuest(quest);
      final index = _quests.indexWhere((q) => q.id == questId);
      if (index != -1) {
        _quests[index] = updated;
        notifyListeners();
      }
      await NotificationService.cancelQuestDeadlineReminder(questId);
    } catch (e) {
      debugPrint('QuestViewModel: erreur complétion: $e');
      rethrow;
    }
  }

  QuestRewards calculateRewards(Quest quest, DateTime completedAt, {bool hasStreakBonus = false}) {
    return QuestRewardsCalculator.calculateRewardsWithTiming(
      quest,
      completedAt,
      hasStreakBonus: hasStreakBonus,
    );
  }

  List<Quest> getCompletedQuestsToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _quests.where((q) {
      if (q.status != QuestStatus.completed || q.completedAt == null) return false;
      return q.completedAt!.isAfter(todayStart) && q.completedAt!.isBefore(todayEnd);
    }).toList();
  }

  List<Quest> getActiveQuestsToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return _quests.where((q) {
      if (q.status != QuestStatus.active) return false;
      if (q.frequency == QuestFrequency.daily) {
        return q.createdAt.isBefore(todayStart.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  List<Quest> getMissedQuests() {
    final now = DateTime.now();
    return _quests.where((q) {
      if (q.status != QuestStatus.active) return false;
      if (q.deadline == null) return false;
      return now.isAfter(q.deadline!);
    }).toList();
  }

  /// Recrée les quêtes récurrentes (daily/weekly/monthly) complétées
  /// dont la période est révolue. Les boss ne sont pas concernés.
  Future<void> resetDailyQuests(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    bool shouldReset(Quest q) {
      if (q.status != QuestStatus.completed) return false;
      if (q.completedAt == null) return false;
      if (q.category == 'boss') return false;
      return switch (q.frequency) {
        QuestFrequency.daily   => q.completedAt!.isBefore(today),
        QuestFrequency.weekly  => q.completedAt!.isBefore(weekStart),
        QuestFrequency.monthly => q.completedAt!.isBefore(monthStart),
        QuestFrequency.oneOff  => false,
      };
    }

    for (final completed in _quests.where(shouldReset).toList()) {
      final alreadyActive = _quests.any((q) =>
        q.id != completed.id &&
        q.title == completed.title &&
        q.frequency == completed.frequency &&
        q.status == QuestStatus.active
      );
      if (alreadyActive) continue;

      final newQuest = Quest(
        userId: userId,
        title: completed.title,
        description: completed.description,
        estimatedDurationMinutes: completed.estimatedDurationMinutes,
        frequency: completed.frequency,
        difficulty: completed.difficulty,
        category: completed.category,
        rarity: completed.rarity,
        status: QuestStatus.active,
        createdAt: today,
        validationType: completed.validationType,
      );
      await addQuest(newQuest);
    }
  }
}
