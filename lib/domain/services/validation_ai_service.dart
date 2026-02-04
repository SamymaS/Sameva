import 'dart:typed_data';

import '../../data/models/quest_model.dart';

/// Résultat de l'analyse IA d'une preuve visuelle pour une quête.
class ValidationResult {
  final int score; // 0 à 100
  final String explanation;
  final bool isValid; // true si score >= 70

  const ValidationResult({
    required this.score,
    required this.explanation,
    required this.isValid,
  });
}

/// Service de validation assistée par IA.
/// L'IA reçoit : titre de la quête, catégorie, preuve visuelle.
/// Elle renvoie : score (0-100), justification textuelle.
/// Seuil de validation : 70/100.
abstract class ValidationAIService {
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  });
}

/// Implémentation mock pour le MVP — simule un délai et un score cohérent avec la quête.
class MockValidationAIService implements ValidationAIService {
  static const int validationThreshold = 70;

  @override
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // Mock : score aléatoire entre 65 et 95 pour démo
    final score = 65 + (imageBytes.length % 31);
    final isValid = score >= validationThreshold;
    final explanation = isValid
        ? 'La preuve visuelle est cohérente avec la quête « ${quest.title} » (catégorie ${quest.category}). Score de confiance : $score/100.'
        : 'La preuve ne permet pas de valider avec suffisamment de confiance la quête « ${quest.title} ». Score : $score/100 (seuil 70).';
    return ValidationResult(
      score: score.clamp(0, 100),
      explanation: explanation,
      isValid: isValid,
    );
  }
}
