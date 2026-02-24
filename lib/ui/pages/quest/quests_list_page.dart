import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';
import 'create_quest_choice_page.dart';

/// Mes Quêtes — liste simple, 2 onglets (À faire / Terminées).
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      await context.read<QuestProvider>().loadQuests(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Quêtes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Consumer<QuestProvider>(
        builder: (context, qp, _) {
          // P1.2 : affichage de l'erreur réseau avec possibilité de réessayer
          if (qp.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      qp.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (qp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final active = qp.activeQuests;
          final completed = qp.completedQuests;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('À faire'),
                    icon: Icon(Icons.list_alt),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Terminées'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_selectedTabIndex},
                onSelectionChanged: (s) => setState(() => _selectedTabIndex = s.first),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _QuestList(quests: active)
                    : _QuestList(quests: completed, completed: true),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateQuestChoicePage()),
          );
          await _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Créer une quête'),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  const _QuestList({required this.quests, this.completed = false});

  final List<Quest> quests;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          completed ? 'Aucune quête terminée' : 'Aucune quête en cours',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final quest = quests[index];
        return ListTile(
          title: Text(quest.title),
          subtitle: Text(
            '${quest.category} · ${quest.estimatedDurationMinutes} min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: completed
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : const Icon(Icons.chevron_right),
          onTap: () {
            if (!completed) {
              Navigator.of(context).pushNamed('/quest/validate', arguments: quest);
            }
          },
        );
      },
    );
  }
}
