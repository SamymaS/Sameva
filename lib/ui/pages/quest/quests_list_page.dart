import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/view_models/quests_list_view_model.dart';
import '../../theme/app_colors.dart';

/// Mes Quêtes — MVVM, Jakob (ListTile familier), Miller (onglets À faire / Terminées, listes courtes).
/// Fitts : FAB + ListTile grandes zones de touch.
class QuestsListPage extends StatefulWidget {
  const QuestsListPage({super.key});

  @override
  State<QuestsListPage> createState() => _QuestsListPageState();
}

class _QuestsListPageState extends State<QuestsListPage> {
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
    return ChangeNotifierProvider<QuestsListViewModel>(
      create: (_) => QuestsListViewModel(
        context.read<QuestProvider>(),
        context.read<AuthProvider>(),
      )..loadQuests(),
      child: Scaffold(
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
        body: Consumer<QuestsListViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('À faire'), icon: Icon(Icons.list_alt)),
                    ButtonSegment(value: 1, label: Text('Terminées'), icon: Icon(Icons.check_circle_outline)),
                  ],
                  selected: {vm.selectedTabIndex},
                  onSelectionChanged: (s) => vm.setTab(s.first),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.selectedTabIndex == 0
                      ? _QuestList(quests: vm.activeQuests)
                      : _QuestList(quests: vm.completedQuests, completed: true),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pushNamed('/create-quest'),
          icon: const Icon(Icons.add),
          label: const Text('Créer une quête'),
        ),
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
          trailing: completed ? const Icon(Icons.check_circle, color: AppColors.success) : const Icon(Icons.chevron_right),
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
