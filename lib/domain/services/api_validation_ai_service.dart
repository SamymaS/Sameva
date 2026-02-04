import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../data/models/quest_model.dart';
import 'validation_ai_service.dart';

/// Implémentation réelle : appelle un backend (ex. Supabase Edge Function)
/// pour analyser l'image avec une IA (ex. GPT-4 Vision).
///
/// Par où commencer :
/// 1. Créer une Edge Function Supabase qui reçoit image_base64 + quest_title + quest_category
///    et renvoie { score, explanation } (voir documentation/IA_ANALYSE_IMAGE.md).
/// 2. Mettre l'URL de l'Edge Function dans .env (ex. VALIDATION_AI_URL).
/// 3. Utiliser ce service à la place de MockValidationAIService dans quest_validation_page.dart.
class ApiValidationAIService implements ValidationAIService {
  ApiValidationAIService({
    required this.baseUrl,
    this.authToken,
    this.timeout = const Duration(seconds: 30),
  });

  /// URL de base du backend (ex. https://xxx.supabase.co/functions/v1/analyze-quest-proof)
  final String baseUrl;

  /// Token pour Authorization: Bearer (clé anon Supabase ou JWT utilisateur)
  final String? authToken;

  final Duration timeout;

  static const int validationThreshold = 70;

  @override
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  }) async {
    final uri = Uri.parse(baseUrl);
    final imageBase64 = base64Encode(imageBytes);

    final body = jsonEncode({
      'image_base64': imageBase64,
      'quest_title': quest.title,
      'quest_category': quest.category,
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API ${response.statusCode}: ${response.body.isNotEmpty ? response.body : "pas de détail"}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final explanation = data['explanation'] as String? ?? 'Pas d\'explication.';
    final isValid = score >= validationThreshold;

    return ValidationResult(
      score: score.clamp(0, 100),
      explanation: explanation,
      isValid: isValid,
    );
  }

  @override
  Future<ValidationResult> analyzeVideoProof({
    required Quest quest,
    required String videoPath,
  }) async {
    // Option 1 : envoyer une frame extraite de la vidéo (nécessite un package type video_thumbnail).
    // Option 2 : ton backend accepte une vidéo (base64 ou upload) et l'analyse.
    // Pour l'instant on lance une erreur pour forcer l'implémentation côté backend si besoin.
    throw UnimplementedError(
      'analyseVideoProof : implémenter envoi d\'une frame ou de la vidéo vers le backend',
    );
  }
}
