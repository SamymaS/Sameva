import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quest_model.dart';
import '../../domain/services/quest_rewards_calculator.dart';

class QuestProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Quest> _quests = [];
  bool _isLoading = false;
  // P1.2 : état d'erreur exposé à l'UI
  String? _error;

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
      debugPrint('QuestProvider: userId vide, chargement annulé');
      _quests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('quests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _quests = (response as List)
          .map((map) => Quest.fromSupabaseMap(Map<String, dynamic>.from(map)))
          .toList();

      // Reset automatique des quêtes daily complétées avant aujourd'hui
      await _resetDailyQuestsIfNeeded();
    } catch (e) {
      debugPrint('QuestProvider: erreur chargement: $e');
      _error = 'Impossible de charger les quêtes. Vérifiez votre connexion.';
      _quests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remet à "active" les quêtes daily complétées avant aujourd'hui.
  Future<void> _resetDailyQuestsIfNeeded() async {
    final todayStart = DateTime.now();
    final today = DateTime(todayStart.year, todayStart.month, todayStart.day);

    final toReset = _quests.where((q) =>
        q.frequency == QuestFrequency.daily &&
        q.status == QuestStatus.completed &&
        q.completedAt != null &&
        q.completedAt!.isBefore(today)).toList();

    for (final quest in toReset) {
      try {
        final reset = quest.copyWith(
          status: QuestStatus.active,
          completedAt: null,
          updatedAt: DateTime.now(),
        );
        await updateQuest(reset);
      } catch (e) {
        debugPrint('QuestProvider: erreur reset daily ${quest.id}: $e');
      }
    }
  }

  Future<void> addQuest(Quest quest) async {
    try {
      // Vérifier que l'utilisateur existe dans la table users
      final userCheck = await _supabase
          .from('users')
          .select('id')
          .eq('id', quest.userId)
          .maybeSingle();

      if (userCheck == null) {
        final authUser = _supabase.auth.currentUser;
        if (authUser == null) {
          throw Exception('Utilisateur non authentifié');
        }

        await _supabase.from('users').insert({
          'id': quest.userId,
          'username': authUser.email?.split('@')[0] ?? 'user_${quest.userId.substring(0, 8)}',
          'display_name': authUser.userMetadata?['display_name'] ??
              authUser.email?.split('@')[0] ??
              'User',
        });

        try {
          await _supabase.from('user_equipment').insert({'user_id': quest.userId});
        } catch (_) {
          // L'équipement existe peut-être déjà
        }
      }

      final data = quest.toSupabaseMap();
      if (quest.id == null) {
        data.remove('id');
      }

      final response = await _supabase
          .from('quests')
          .insert(data)
          .select()
          .single();

      final newQuest = Quest.fromSupabaseMap(response);
      _quests.insert(0, newQuest);
      notifyListeners();
    } catch (e) {
      debugPrint('QuestProvider: erreur création: $e');
      rethrow;
    }
  }

  Future<void> updateQuest(Quest quest) async {
    try {
      if (quest.id == null) throw Exception('Impossible de mettre à jour une quête sans ID');

      final data = quest.toSupabaseMap();
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('quests')
          .update(data)
          .eq('id', quest.id!);

      final index = _quests.indexWhere((q) => q.id == quest.id);
      if (index != -1) {
        _quests[index] = quest;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('QuestProvider: erreur mise à jour: $e');
      rethrow;
    }
  }

  Future<void> deleteQuest(String questId) async {
    try {
      await _supabase.from('quests').delete().eq('id', questId);
      _quests.removeWhere((q) => q.id == questId);
      notifyListeners();
    } catch (e) {
      debugPrint('QuestProvider: erreur suppression: $e');
      rethrow;
    }
  }

  Future<void> completeQuest(String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      final updatedQuest = quest.copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateQuest(updatedQuest);
    } catch (e) {
      debugPrint('QuestProvider: erreur complétion: $e');
      rethrow;
    }
  }

  /// Retourne les récompenses calculées pour une quête.
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
