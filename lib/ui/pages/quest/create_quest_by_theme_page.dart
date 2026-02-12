import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/quest_templates.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';

/// Mode "Par thème" : choix du thème (Sport, Loisir, Maison) puis liste de tâches préconfigurées.
class CreateQuestByThemePage extends StatefulWidget {
  const CreateQuestByThemePage({super.key});

  @override
  State<CreateQuestByThemePage> createState() => _CreateQuestByThemePageState();
}

class _CreateQuestByThemePageState extends State<CreateQuestByThemePage> {
  String? _selectedTheme;

  @override
  Widget build(BuildContext context) {
    final templates = _selectedTheme == null
        ? <QuestTemplate>[]
        : questTemplatesByTheme[_selectedTheme]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTheme == null ? 'Choisir un thème' : _selectedTheme!),
        leading: _selectedTheme != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedTheme = null),
              )
            : null,
      ),
      body: _selectedTheme == null ? _buildThemeGrid() : _buildTemplateList(templates),
    );
  }

  Widget _buildThemeGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sélectionnez un thème pour voir les tâches préconfigurées.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ...themeCategories.map((theme) {
            final icon = _iconForTheme(theme);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton.icon(
                onPressed: () => setState(() => _selectedTheme = theme),
                icon: Icon(icon),
                label: Text(theme),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.centerLeft,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconForTheme(String theme) {
    switch (theme) {
      case 'Sport':
        return Icons.fitness_center;
      case 'Loisir':
        return Icons.palette_outlined;
      case 'Maison':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildTemplateList(List<QuestTemplate> templates) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = templates[index];
        return ListTile(
          title: Text(t.title),
          subtitle: Text(
            '${t.defaultDurationMinutes} min · ${t.validationType == ValidationType.photo ? "Preuve photo" : "Validation simple"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () => _showCreateDialog(t),
        );
      },
    );
  }

  Future<void> _showCreateDialog(QuestTemplate template) async {
    int duration = template.defaultDurationMinutes;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(template.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Durée estimée :'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: duration,
                    items: [15, 20, 25, 30, 45, 60]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => duration = v ?? duration),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Créer la quête'),
                ),
              ],
            );
          },
        );
      },
    );
    if (created != true || !mounted) return;
    await _createQuestFromTemplate(template, duration);
  }

  Future<void> _createQuestFromTemplate(QuestTemplate template, int durationMinutes) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day, 23, 59);

    final quest = Quest(
      userId: userId,
      title: template.title,
      estimatedDurationMinutes: durationMinutes,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: template.category,
      rarity: QuestRarity.common,
      status: QuestStatus.active,
      validationType: template.validationType,
      deadline: deadline,
    );

    await context.read<QuestProvider>().addQuest(quest);
    if (!mounted) return;
    Navigator.of(context).pop(); // back to choice page
    Navigator.of(context).pop(); // back to list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quête créée')),
    );
  }
}
