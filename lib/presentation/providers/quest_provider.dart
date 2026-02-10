import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/quest_model.dart';
import '../../domain/services/quest_rewards_calculator.dart';
import '../../domain/services/bonus_malus_service.dart';
import 'player_provider.dart';

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
      // Vérifier que l'utilisateur existe dans la table users
      final userCheck = await _supabase
          .from('users')
          .select('id')
          .eq('id', quest.userId)
          .maybeSingle();
      
      if (userCheck == null) {
        // L'utilisateur n'existe pas, le créer
        final authUser = _supabase.auth.currentUser;
        if (authUser == null) {
          throw Exception('Utilisateur non authentifié');
        }
        
        // Créer l'utilisateur dans la table users
        await _supabase.from('users').insert({
          'id': quest.userId,
          'username': authUser.email?.split('@')[0] ?? 'user_${quest.userId.substring(0, 8)}',
          'display_name': authUser.userMetadata?['display_name'] ?? authUser.email?.split('@')[0] ?? 'User',
        });
        
        // Créer l'équipement vide pour l'utilisateur
        try {
          await _supabase.from('user_equipment').insert({
            'user_id': quest.userId,
          });
        } catch (_) {
          // L'équipement existe peut-être déjà, ignorer l'erreur
        }
      }
      
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

  /// Complète une quête et calcule les récompenses avec bonus/malus
  /// Retourne les récompenses finales pour affichage dans l'UI
  Future<QuestRewards> completeQuestWithRewards(String questId, PlayerProvider playerProvider) async {
    final quest = _quests.firstWhere((q) => q.id == questId);
    final now = DateTime.now();
    final userId = quest.userId;

    // 1. Compléter la quête
    await completeQuest(questId);

    // 2. Calculer les récompenses de base avec timing
    final baseRewards = QuestRewardsCalculator.calculateRewardsWithTiming(
      quest,
      now,
      hasStreakBonus: playerProvider.hasStreakBonus,
    );

    // 3. Calculer le multiplicateur bonus/malus
    final bonusMalus = BonusMalusService.calculateTotalBonusMalus(
      completedQuestsToday: getCompletedQuestsToday(),
      activeQuestsToday: getActiveQuestsToday(),
      missedQuests: getMissedQuests(),
      streak: playerProvider.stats?.streak ?? 0,
      lastActiveDate: playerProvider.stats?.lastActiveDate,
    );

    // 4. Appliquer le multiplicateur
    final finalXP = BonusMalusService.calculateExperienceModifier(bonusMalus, baseRewards.experience);
    final finalGold = BonusMalusService.calculateGoldModifier(bonusMalus, baseRewards.gold);

    // 5. Distribuer les récompenses
    await playerProvider.addExperience(userId, finalXP);
    await playerProvider.addGold(userId, finalGold);
    if (baseRewards.crystals > 0) {
      await playerProvider.addCrystals(userId, baseRewards.crystals);
    }
    await playerProvider.updateStreak(userId);
    await playerProvider.incrementQuestsCompleted(userId);

    // 6. Vérifier les achievements
    await playerProvider.checkAndUnlockAchievements(userId);

    return QuestRewards(
      experience: finalXP,
      gold: finalGold,
      crystals: baseRewards.crystals,
      bonusType: baseRewards.bonusType,
      multiplier: bonusMalus,
    );
  }
} 