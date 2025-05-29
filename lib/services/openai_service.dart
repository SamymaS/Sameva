import 'package:dart_openai/dart_openai.dart';

class OpenAIService {
  static const String _modelName = 'gpt-3.5-turbo';
  
  static void initialize(String apiKey) {
    OpenAI.apiKey = apiKey;
  }

  static Future<String> generateQuestSuggestions(String mainQuest) async {
    try {
      final completion = await OpenAI.instance.chat.create(
        model: _modelName,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              const OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'Tu es un maître de jeu RPG qui aide à décomposer une quête principale en sous-quêtes plus petites.'
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'Décompose cette quête en 3 sous-quêtes plus petites et réalisables : $mainQuest'
              ),
            ],
          ),
        ],
      );

      if (completion.choices.isEmpty) {
        return 'Aucune suggestion générée';
      }

      final content = completion.choices.first.message.content;
      if (content == null || content.isEmpty) {
        return 'Aucune suggestion générée';
      }

      return content.first.text ?? 'Aucune suggestion générée';
    } catch (e) {
      return 'Erreur lors de la génération des suggestions : $e';
    }
  }
} 