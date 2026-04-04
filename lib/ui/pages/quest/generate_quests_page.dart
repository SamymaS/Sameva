import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/supabase_config.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/claude_quest_generator_service.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';

/// Page de génération de quêtes personnalisées via Claude IA.
class GenerateQuestsPage extends StatefulWidget {
  const GenerateQuestsPage({super.key});

  @override
  State<GenerateQuestsPage> createState() => _GenerateQuestsPageState();
}

class _GenerateQuestsPageState extends State<GenerateQuestsPage> {
  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _error;
  final Set<int> _addingIndices = {};

  Future<void> _generate() async {
    final apiKey = SupabaseConfig.anthropicApiKey;
    if (apiKey == null) {
      setState(() => _error = 'Clé API Anthropic non configurée dans le fichier .env.');
      return;
    }

    final player = context.read<PlayerProvider>().stats;
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) {
      setState(() => _error = 'Utilisateur non connecté.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _quests = [];
    });

    try {
      final service = ClaudeQuestGeneratorService(apiKey: apiKey);
      final quests = await service.generateQuests(
        userId: userId,
        playerLevel: player?.level ?? 1,
        streak: player?.streak ?? 0,
        totalQuestsCompleted: player?.totalQuestsCompleted ?? 0,
      );
      if (mounted) setState(() => _quests = quests);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addQuest(int index) async {
    setState(() => _addingIndices.add(index));
    try {
      await context.read<QuestProvider>().addQuest(_quests[index]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('« ${_quests[index].title} » ajoutée !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingIndices.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>().stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Générer des quêtes avec IA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Résumé profil
            _ProfileSummaryCard(
              level: player?.level ?? 1,
              streak: player?.streak ?? 0,
              totalCompleted: player?.totalQuestsCompleted ?? 0,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Génération en cours…' : 'Générer 3 quêtes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_quests.isNotEmpty) ...[
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _quests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _QuestCard(
                    quest: _quests[i],
                    isAdding: _addingIndices.contains(i),
                    onAdd: () => _addQuest(i),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.level,
    required this.streak,
    required this.totalCompleted,
  });

  final int level;
  final int streak;
  final int totalCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Niveau', value: '$level'),
          _Stat(label: 'Streak', value: '${streak}j'),
          _Stat(label: 'Quêtes', value: '$totalCompleted'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.isAdding,
    required this.onAdd,
  });

  final Quest quest;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _DifficultyBadge(difficulty: quest.difficulty),
              ],
            ),
            if (quest.description != null && quest.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                quest.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(quest.category,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${quest.estimatedDurationMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.repeat,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_frequencyLabel(quest.frequency),
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: isAdding ? null : onAdd,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: isAdding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _frequencyLabel(QuestFrequency f) => switch (f) {
        QuestFrequency.oneOff => 'Unique',
        QuestFrequency.daily => 'Quotidien',
        QuestFrequency.weekly => 'Hebdo',
        QuestFrequency.monthly => 'Mensuel',
      };
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      1 => Colors.green,
      2 => Colors.lightGreen,
      3 => Colors.orange,
      4 => Colors.deepOrange,
      _ => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Diff. $difficulty',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
