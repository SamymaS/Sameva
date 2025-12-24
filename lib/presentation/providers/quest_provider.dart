import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quest_model.dart';
import '../../domain/services/quest_rewards_calculator.dart';

class QuestProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Quest> _quests = [];
  bool _isLoading = false;
  
  List<Quest> get quests => _quests;
  bool get isLoading => _isLoading;
  List<Quest> get activeQuests => _quests.where((q) => q.status == QuestStatus.active).toList();
  List<Quest> get completedQuests => _quests.where((q) => q.status == QuestStatus.completed).toList();
  
  Future<void> loadQuests(String userId) async {
    // Vérifier que userId n'est pas vide
    if (userId.isEmpty) {
      print('Erreur: userId est vide');
      _quests = [];
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
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
    } catch (e) {
      print('Erreur lors du chargement des quêtes: $e');
      _quests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuest(Quest quest) async {
    try {
      final data = quest.toSupabaseMap();
      // Retirer l'id s'il est null pour laisser Supabase le générer
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
      print('Erreur lors de la création de la quête: $e');
      rethrow;
    }
  }

  Future<void> updateQuest(Quest quest) async {
    try {
      if (quest.id == null) throw Exception('Impossible de mettre à jour une quête sans ID');
      
      final data = quest.toSupabaseMap();
      data.remove('id'); // Ne pas mettre à jour l'ID
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
      print('Erreur lors de la mise à jour de la quête: $e');
      rethrow;
    }
  }

  Future<void> deleteQuest(String questId) async {
    try {
      await _supabase
          .from('quests')
          .delete()
          .eq('id', questId);
      
      _quests.removeWhere((q) => q.id == questId);
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la suppression de la quête: $e');
      rethrow;
    }
  }

  /// Obtient les quêtes complétées aujourd'hui
  List<Quest> getCompletedQuestsToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _quests.where((q) {
      if (q.status != QuestStatus.completed || q.completedAt == null) return false;
      return q.completedAt!.isAfter(todayStart) && q.completedAt!.isBefore(todayEnd);
    }).toList();
  }

  /// Obtient les quêtes actives aujourd'hui
  List<Quest> getActiveQuestsToday() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    return _quests.where((q) {
      if (q.status != QuestStatus.active) return false;
      // Quêtes quotidiennes créées aujourd'hui ou avant
      if (q.frequency == QuestFrequency.daily) {
        return q.createdAt.isBefore(todayStart.add(const Duration(days: 1)));
      }
      // Autres quêtes actives
      return true;
    }).toList();
  }

  /// Obtient les quêtes manquées (actives mais non complétées après leur échéance)
  List<Quest> getMissedQuests() {
    final now = DateTime.now();
    return _quests.where((q) {
      if (q.status != QuestStatus.active) return false;
      if (q.deadline != null) {
        return now.isAfter(q.deadline!);
      }
      // Fallback: utiliser estimatedDurationMinutes
      final deadline = q.createdAt.add(Duration(minutes: q.estimatedDurationMinutes));
      return now.isAfter(deadline);
    }).toList();
  }

  Future<void> completeQuest(String questId) async {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      final updatedQuest = quest.copyWith(
        status: QuestStatus.completed,
        isCompleted: true,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateQuest(updatedQuest);
    } catch (e) {
      print('Erreur lors de la complétion de la quête: $e');
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