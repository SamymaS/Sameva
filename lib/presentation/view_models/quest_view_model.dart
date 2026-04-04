import 'package:flutter/foundation.dart';
import '../../data/models/quest_model.dart';
import '../../data/repositories/quest_repository.dart';
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
      if (q.deadline != null) {
        return now.isAfter(q.deadline!);
      }
      final deadline = q.createdAt.add(Duration(minutes: q.estimatedDurationMinutes));
      return now.isAfter(deadline);
    }).toList();
  }
}
