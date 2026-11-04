import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/quest_model.dart';
import 'quest_suggestion_service.dart';

/// Appel brut de l'Edge Function : renvoie (statut HTTP, corps décodé).
typedef SuggestInvoker = Future<(int, Object?)> Function(Map<String, dynamic> body);

/// Erreur lisible renvoyée à l'écran (quota atteint, MougiBot indisponible...).
class QuestSuggestionException implements Exception {
  QuestSuggestionException(this.userMessage, {this.code});
  final String userMessage;
  final String? code;
  @override
  String toString() => userMessage;
}

/// Implémentation réelle : appelle l'Edge Function Supabase `suggest-quests`
/// avec la session de l'utilisateur (Sprint 2 : la clé anon seule est
/// refusée, le serveur lit le profil en base et applique un quota quotidien).
class ApiQuestSuggestionService implements QuestSuggestionService {
  ApiQuestSuggestionService({SuggestInvoker? invoker})
      : _invoke = invoker ?? _supabaseInvoker;

  final SuggestInvoker _invoke;

  static Future<(int, Object?)> _supabaseInvoker(Map<String, dynamic> body) async {
    try {
      final res = await Supabase.instance.client.functions
          .invoke('suggest-quests', body: body);
      return (res.status, res.data);
    } on FunctionException catch (e) {
      return (e.status, e.details);
    }
  }

  @override
  Future<List<Quest>> suggestQuests({
    required String userId,
    required QuestSuggestionRequest request,
  }) async {
    // Seuls ces champs sont pris en compte par le serveur.
    final body = <String, dynamic>{
      if (request.favoriteCategory != null) 'favorite_category': request.favoriteCategory,
    };
    final (status, data) = await _invoke(body);
    if (status != 200) {
      final code = data is Map ? data['code'] as String? : null;
      throw QuestSuggestionException(
        switch (code) {
          'plafond_atteint' => 'MougiBot a assez cherché pour aujourd\'hui. Reviens demain !',
          'non_authentifie' => 'Connecte-toi pour demander des quêtes à MougiBot.',
          _ => 'MougiBot est indisponible pour le moment. Réessaie plus tard.',
        },
        code: code,
      );
    }
    return _parseQuests(data is String ? data : jsonEncode(data), userId);
  }

  List<Quest> _parseQuests(String responseBody, String userId) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

    // L'Edge Function renvoie toujours { "quests": [...] }
    final rawList = decoded['quests'] as List<dynamic>;

    return rawList.map((item) {
      final map = item as Map<String, dynamic>;
      final frequency = QuestFrequency.fromSupabaseString(
        (map['frequency'] as String?) ?? 'one_off',
      );
      final difficulty = ((map['difficulty'] as num?) ?? 1).toInt().clamp(1, 4);
      final duration =
          ((map['estimated_duration_minutes'] as num?) ?? 30).toInt();

      return Quest(
        userId: userId,
        title: map['title'] as String,
        description: map['description'] as String?,
        category: map['category'] as String? ?? 'Général',
        difficulty: difficulty,
        estimatedDurationMinutes: duration,
        frequency: frequency,
        rarity: QuestRarity.common,
        status: QuestStatus.active,
      );
    }).toList();
  }
}
