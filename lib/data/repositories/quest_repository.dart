import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quest_model.dart';
import 'user_repository.dart';

/// Accès CRUD aux quêtes stockées dans Supabase.
/// Pas d'état UI — retourne des listes/objets ou lance des exceptions.
class QuestRepository {
  final SupabaseClient _supabase;
  final UserRepository _userRepository;

  QuestRepository(this._supabase, this._userRepository);

  /// Charge toutes les quêtes d'un utilisateur.
  ///
  /// Sprint 1 : une quête terminée reste terminée (historique). Les quêtes
  /// récurrentes sont recréées comme NOUVELLES quêtes par
  /// [QuestViewModel.resetDailyQuests], jamais réactivées.
  Future<List<Quest>> loadQuests(String userId) async {
    final response = await _supabase
        .from('quests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
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
}
