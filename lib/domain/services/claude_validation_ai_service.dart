import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/quest_model.dart';
import 'validation_ai_service.dart';

/// Implémentation de [ValidationAIService] via l'API Claude (Anthropic).
/// Utilise Claude Vision pour analyser les preuves photo des quêtes.
class ClaudeValidationAIService implements ValidationAIService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';
  static const _validationThreshold = 70;

  final String apiKey;

  ClaudeValidationAIService({required this.apiKey});

  @override
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final prompt =
        'Quête : "${quest.title}" (catégorie : ${quest.category}). '
        "Analyse cette image comme preuve que la quête a été accomplie. "
        'Réponds UNIQUEMENT en JSON valide sans balise markdown, avec les champs : '
        '{"score": <int 0-100>, "explanation": "<string en français>"}. '
        'Score 0 = aucun lien avec la quête, 100 = preuve parfaite.';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 512,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': prompt,
            },
          ],
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
      debugPrint('Claude API error ${response.statusCode}: ${response.body}');
      final errorMsg = _extractApiError(response.body, response.statusCode);
      throw Exception(errorMsg);
    }

    return _parseResponse(response.body, quest);
  }

  @override
  Future<ValidationResult> analyzeVideoProof({
    required Quest quest,
    required String videoPath,
  }) async {
    // Claude Vision ne supporte pas encore les vidéos — fallback mock.
    await Future<void>.delayed(const Duration(seconds: 1));
    const score = 75;
    return const ValidationResult(
      score: score,
      explanation: 'Analyse vidéo non disponible avec Claude Vision. Score estimé : 75/100.',
      isValid: true,
    );
  }

  ValidationResult _parseResponse(String responseBody, Quest quest) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final text =
          (decoded['content'] as List<dynamic>).first['text'] as String;

      // Extrait le JSON de la réponse (peut contenir du texte autour)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) return _fallback(quest, text);

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final score = (parsed['score'] as num).round().clamp(0, 100);
      final explanation = parsed['explanation'] as String? ??
          'Analyse terminée. Score : $score/100.';

      return ValidationResult(
        score: score,
        explanation: explanation,
        isValid: score >= _validationThreshold,
      );
    } catch (_) {
      return _fallback(quest, responseBody);
    }
  }

  ValidationResult _fallback(Quest quest, String rawText) {
    const score = 50;
    return ValidationResult(
      score: score,
      explanation:
          'Impossible de parser la réponse Claude pour « ${quest.title} ». '
          'Détail : ${rawText.substring(0, rawText.length.clamp(0, 500))}',
      isValid: false,
    );
  }

  String _extractApiError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? body;
      return 'Claude API ($statusCode) : $message';
    } catch (_) {
      return 'Claude API ($statusCode) : $body';
    }
  }
}
