import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quest_model.dart';
import 'user_repository.dart';

/// Accès CRUD aux quêtes stockées dans Supabase.
/// Pas d'état UI — retourne des listes/objets ou lance des exceptions.
class QuestRepository {
  final SupabaseClient _supabase;
  final UserRepository _userRepository;

  QuestRepository(this._supabase, this._userRepository);

  /// Charge toutes les quêtes d'un utilisateur, puis remet à "active"
  /// les quêtes récurrentes complétées sur une période passée.
  Future<List<Quest>> loadQuests(String userId) async {
    final response = await _supabase
        .from('quests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final quests = (response as List)
        .map((map) => Quest.fromSupabaseMap(Map<String, dynamic>.from(map)))
        .toList();

    final hadResets = await _resetRecurringQuestsIfNeeded(quests);
    if (!hadResets) return quests;

    // Recharger depuis Supabase pour avoir l'état après reset
    final refreshed = await _supabase
        .from('quests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (refreshed as List)
        .map((map) => Quest.fromSupabaseMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  /// Crée une quête (crée le profil utilisateur si nécessaire).
  Future<Quest> addQuest(Quest quest) async {
    await _userRepository.ensureUserExists(quest.userId);

    final data = quest.toSupabaseMap();
    if (quest.id == null) data.remove('id');

    final response = await _supabase
        .from('quests')
        .insert(data)
        .select()
        .single();

    return Quest.fromSupabaseMap(response);
  }

  Future<Quest> updateQuest(Quest quest) async {
    if (quest.id == null) throw Exception('Impossible de mettre à jour une quête sans ID');

    final data = quest.toSupabaseMap();
    data.remove('id');
    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('quests')
        .update(data)
        .eq('id', quest.id!);

    return quest;
  }

  Future<void> deleteQuest(String questId) async {
    await _supabase.from('quests').delete().eq('id', questId);
  }

  Future<Quest> completeQuest(Quest quest) async {
    return updateQuest(quest.copyWith(
      status: QuestStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Remet à "active" les quêtes récurrentes (daily/weekly/monthly) dont
  /// la période est révolue. Retourne true si au moins une quête a été réinitialisée.
  Future<bool> _resetRecurringQuestsIfNeeded(List<Quest> quests) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Début de la semaine courante (lundi à minuit)
    final weekdayOffset = (now.weekday - 1) % 7; // lundi = 0
    final weekStart = todayStart.subtract(Duration(days: weekdayOffset));

    // Début du mois courant
    final monthStart = DateTime(now.year, now.month, 1);

    bool shouldReset(Quest q) {
      if (q.status != QuestStatus.completed) return false;
      if (q.completedAt == null) return false;
      return switch (q.frequency) {
        QuestFrequency.daily   => q.completedAt!.isBefore(todayStart),
        QuestFrequency.weekly  => q.completedAt!.isBefore(weekStart),
        QuestFrequency.monthly => q.completedAt!.isBefore(monthStart),
        QuestFrequency.oneOff  => false,
      };
    }

    final toReset = quests.where(shouldReset).toList();

    for (final quest in toReset) {
      try {
        await updateQuest(quest.copyWith(
          status: QuestStatus.active,
          completedAt: null,
          updatedAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('QuestRepository: erreur reset ${quest.frequency.name} ${quest.id}: $e');
      }
    }

    return toReset.isNotEmpty;
  }
}
