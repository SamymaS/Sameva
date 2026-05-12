---
name: sameva-ia-integration
description: Intégration de MougiBot (validation IA des preuves de quête) dans Sameva. À utiliser pour brancher l'API Claude, gérer le service ValidationAIService, modifier le prompt, ajuster le seuil, ou ajouter un fallback. Pour le code de l'Edge Function elle-même, voir sameva-edge-functions.
---

# Intégration IA Sameva — MougiBot

## Identités

- **Mougi** = compagnon visuel (chat, asset graphique)
- **MougiBot** = esprit analytique de Mougi, agent IA qui valide les preuves de quête

Ne jamais dire "validation IA", "Claude", "OpenAI" à l'utilisateur. Toujours **MougiBot**.

## Architecture

```
QuestValidationPage
  └─ ValidationAIService (interface)
      ├─ ApiValidationAIService    → Edge Function → Claude Haiku Vision
      └─ MockValidationAIService   → fallback local (offline / erreur)
```

Sélection automatique au démarrage selon `VALIDATION_AI_URL` dans `.env` :
- URL définie → `ApiValidationAIService`
- URL vide → `MockValidationAIService`

## Contrat de service

```dart
// domain/services/validation_ai_service.dart
class ValidationResult {
  final int score;          // 0 à 100
  final String explanation;
  final bool isValid;       // score >= 70

  const ValidationResult({
    required this.score,
    required this.explanation,
    required this.isValid,
  });
}

abstract class ValidationAIService {
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  });
}
```

## Implémentation API

```dart
// domain/services/api_validation_ai_service.dart
class ApiValidationAIService implements ValidationAIService {
  static const int validationThreshold = 70;
  static const Duration timeout = Duration(seconds: 30);

  ApiValidationAIService({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;

  @override
  Future<ValidationResult> analyzeProof({
    required Quest quest,
    required Uint8List imageBytes,
  }) async {
    final body = jsonEncode({
      'image_base64': base64Encode(imageBytes),
      'quest_title': quest.title,
      'quest_category': quest.category,
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: body,
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw HttpException(
        'MougiBot HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final score = (json['score'] as num).toInt();
    return ValidationResult(
      score: score,
      explanation: json['explanation'] as String,
      isValid: score >= validationThreshold,
    );
  }
}
```

## Seuil de validation et récompenses

| Score | Action utilisateur | Récompenses |
|---|---|---|
| **≥ 70** | Validation automatique | 100 % XP + or + cristaux |
| **< 70** | Choix : valider manuellement OU reprendre photo | 50 % XP + or si validation manuelle |
| **Erreur API** | Fallback Mock + validation manuelle disponible | 50 % XP + or |

Calcul des récompenses réduites :
```dart
final adjusted = QuestRewards(
  experience: (base.experience * 0.5).round(),
  gold: (base.gold * 0.5).round(),
  crystals: base.crystals,  // cristaux inchangés
);
```

## Pattern fallback

```dart
Future<ValidationResult> validateWithFallback(
  Quest quest, Uint8List image,
) async {
  try {
    return await _validationService.analyzeProof(
      quest: quest, imageBytes: image,
    );
  } catch (e) {
    debugPrint('MougiBot : $e, fallback mock');
    return MockValidationAIService().analyzeProof(
      quest: quest, imageBytes: image,
    );
  }
}
```

## Textes UI à utiliser

```dart
const String kAnalyzingMessage = "MougiBot analyse ta preuve...";
const List<String> kAnalyzingTips = [
  "MougiBot inspecte les détails...",
  "MougiBot consulte son grimoire...",
  "MougiBot scrute ton image attentivement...",
];
String formatExplanation(String raw) => "🐱 MougiBot a vu : « $raw »";
const String kFallbackMessage = 
    "MougiBot est en pause, valide manuellement (récompenses à 50 %)";
```

## Règles de l'art

1. **Aucune clé Anthropic dans le code Flutter.** La clé vit uniquement dans les secrets Supabase, utilisée par l'Edge Function.
2. **Toujours un fallback Mock** si MougiBot indisponible.
3. **Seuil 70/100** — constante `validationThreshold`, à ne pas hardcoder ailleurs.
4. **L'utilisateur n'est jamais bloqué.** Validation manuelle toujours dispo (50 % récompenses).
5. **JSON Claude parsé avec try/catch.** Claude peut envelopper son JSON dans du markdown malgré les consignes.
6. **Modifier le prompt MougiBot ?** Le faire dans `supabase/functions/analyze-quest-proof/index.ts`. Tester sur les 10 cas limites avant déploiement.

## Coût et observabilité

- **~0,003 € par validation** (Claude Haiku 4.5)
- Plafond conseillé sur compte Anthropic : 10 €/mois
- Logs : `supabase functions logs analyze-quest-proof --tail`
- Console Anthropic : https://console.anthropic.com pour le détail tokens

## Fichiers de référence

- `lib/domain/services/validation_ai_service.dart`
- `lib/domain/services/api_validation_ai_service.dart`
- `lib/domain/services/mock_validation_ai_service.dart`
- `lib/ui/pages/quest/quest_validation_page.dart`
- `supabase/functions/analyze-quest-proof/index.ts`
