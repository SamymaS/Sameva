import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/quest_model.dart';
import 'quest_suggestion_service.dart';

/// Implémentation réelle : appelle l'Edge Function Supabase `suggest-quests`.
/// L'URL et le token sont injectés via le constructeur (lus depuis .env).
class ApiQuestSuggestionService implements QuestSuggestionService {
  ApiQuestSuggestionService({
    required this.baseUrl,
    this.authToken,
    this.timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// URL de l'Edge Function (ex. https://xxx.supabase.co/functions/v1/suggest-quests)
  final String baseUrl;

  /// Token Authorization: Bearer (clé anon Supabase)
  final String? authToken;

  final Duration timeout;

  final http.Client _httpClient;

  @override
  Future<List<Quest>> suggestQuests({
    required String userId,
    required QuestSuggestionRequest request,
  }) async {
    final uri = Uri.parse(baseUrl);
    final body = jsonEncode(request.toJson());

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await _httpClient
        .post(uri, headers: headers, body: body)
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API ${response.statusCode}: ${response.body.isNotEmpty ? response.body : "pas de détail"}',
      );
    }

    return _parseQuests(response.body, userId);
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
