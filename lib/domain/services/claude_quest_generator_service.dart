import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/quest_model.dart';

/// Génère des quêtes personnalisées via l'API Claude (Anthropic).
class ClaudeQuestGeneratorService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  final String apiKey;

  ClaudeQuestGeneratorService({required this.apiKey});

  /// Génère 3 quêtes adaptées au profil du joueur.
  /// [userId] est requis pour construire les objets [Quest].
  Future<List<Quest>> generateQuests({
    required String userId,
    required int playerLevel,
    required int streak,
    required int totalQuestsCompleted,
    String? favoriteCategory,
  }) async {
    final categoryHint = favoriteCategory != null
        ? 'Sa catégorie préférée est « $favoriteCategory ».'
        : '';

    final prompt =
        'Tu es un générateur de quêtes pour un jeu RPG de productivité. '
        'Profil joueur : niveau $playerLevel, streak $streak jours, '
        '$totalQuestsCompleted quêtes complétées. $categoryHint\n\n'
        'Génère exactement 3 quêtes variées et motivantes adaptées à ce profil. '
        'Réponds UNIQUEMENT avec un tableau JSON valide (sans balise markdown) : '
        '[{"title": string, "description": string, "category": string, '
        '"difficulty": int (1-5), "estimated_duration_minutes": int, '
        '"frequency": "one_off"|"daily"|"weekly"}]. '
        'Les titres et descriptions doivent être en français.';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 1024,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur API Claude (${response.statusCode}) : ${response.body}');
    }

    return _parseQuests(response.body, userId);
  }

  List<Quest> _parseQuests(String responseBody, String userId) {
    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final text = (decoded['content'] as List<dynamic>).first['text'] as String;

    // Extrait le tableau JSON de la réponse
    final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (jsonMatch == null) {
      throw Exception('Réponse Claude invalide : impossible d\'extraire les quêtes.');
    }

    final list = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      final frequency = QuestFrequency.fromSupabaseString(
        (map['frequency'] as String?) ?? 'one_off',
      );
      final difficulty = ((map['difficulty'] as num?) ?? 1).toInt().clamp(1, 5);
      final duration = ((map['estimated_duration_minutes'] as num?) ?? 30).toInt();

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
