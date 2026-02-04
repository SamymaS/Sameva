import 'package:flutter/material.dart';
import 'create_quest_by_theme_page.dart';
import 'create_quest_page.dart';

/// Écran de choix : Par thème (tâches préconfigurées) ou Quête personnalisée.
class CreateQuestChoicePage extends StatelessWidget {
  const CreateQuestChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une quête')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Comment voulez-vous créer votre quête ?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateQuestByThemePage(),
                  ),
                );
              },
              icon: const Icon(Icons.category_outlined),
              label: const Text('Par thème (Sport, Loisir, Maison)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choisissez une tâche préconfigurée dans un thème.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateQuestPage(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Quête personnalisée'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous savez déjà ce que vous voulez faire ? Créez une quête sur mesure.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
