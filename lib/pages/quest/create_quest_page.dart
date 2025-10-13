import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dart_openai/dart_openai.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/quest_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';

class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  QuestFrequency _frequency = QuestFrequency.once;
  int _difficulty = 1;
  String _category = 'Personnel';
  List<String> _subQuests = [];
  bool _isLoading = false;
  bool _isGeneratingSubQuests = false;

  final List<String> _categories = [
    'Personnel',
    'Professionnel',
    'Santé',
    'Sport',
    'Études',
    'Loisirs',
    'Social',
    'Autre',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _generateSubQuests() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir le titre et la description'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGeneratingSubQuests = true);

    try {
      final prompt = '''
Décompose la quête suivante en sous-tâches concrètes et réalisables :

Titre : ${_titleController.text}
Description : ${_descriptionController.text}
Catégorie : $_category
Fréquence : ${_frequency.toString().split('.').last}
Difficulté : $_difficulty/5

Format de réponse souhaité : Une liste de sous-tâches, une par ligne.
''';

      final completion = await OpenAI.instance.chat.create(
        model: 'gpt-3.5-turbo',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      if (completion.choices.isNotEmpty) {
        final content = completion.choices.first.message.content;
        if (content != null && content.isNotEmpty) {
          final textContent = content.first.text;
          if (textContent != null) {
            final subQuests = textContent
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();

            setState(() {
              _subQuests = subQuests;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSubQuests = false);
      }
    }
  }

  QuestRarity _calculateRarity() {
    final score = _difficulty + (_subQuests.length / 2).round();
    
    if (score <= 2) return QuestRarity.common;
    if (score <= 4) return QuestRarity.uncommon;
    if (score <= 6) return QuestRarity.rare;
    if (score <= 8) return QuestRarity.veryRare;
    if (score <= 10) return QuestRarity.epic;
    if (score <= 12) return QuestRarity.legendary;
    return QuestRarity.mythic;
  }

  Future<void> _createQuest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final quest = Quest(
        title: _titleController.text,
        description: _descriptionController.text,
        estimatedDuration: Duration(
          minutes: int.parse(_durationController.text),
        ),
        frequency: _frequency,
        difficulty: _difficulty,
        category: _category,
        rarity: _calculateRarity(),
        subQuests: _subQuests,
      );

      await context.read<QuestProvider>().addQuest(userId, quest);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création : ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Quête'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la quête',
                hintText: 'Ex: Apprendre à jouer de la guitare',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre quête en détail',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée estimée (en minutes)',
                hintText: 'Ex: 60',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une durée';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
              ),
              items: QuestFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _frequency = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Difficulté',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _difficulty.toString(),
                  onChanged: (value) {
                    setState(() => _difficulty = value.round());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isGeneratingSubQuests ? null : _generateSubQuests,
              icon: _isGeneratingSubQuests
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingSubQuests
                    ? 'Génération en cours...'
                    : 'Générer les sous-quêtes',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_subQuests.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Sous-quêtes générées',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subQuests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(_subQuests[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _subQuests.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createQuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'CRÉER LA QUÊTE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 