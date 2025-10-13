import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/quest_provider.dart';
import '../../core/providers/player_provider.dart';
import '../../theme/app_theme.dart';
import '../quest/create_quest_page.dart';
import 'widgets/player_stats_card.dart';
import 'widgets/quest_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    await Future.wait([
      context.read<QuestProvider>().loadQuests(userId),
      context.read<PlayerProvider>().loadPlayerStats(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final questProvider = context.watch<QuestProvider>();
    final stats = playerProvider.stats;

    if (stats == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, Héros !',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Niveau ${stats.level}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),
                  ],
                ),
              ),
              const PlayerStatsCard(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quêtes du jour',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle quête'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateQuestPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: QuestList(
                  quests: questProvider.activeQuests,
                  onQuestCompleted: (questId) async {
                    final userId = context.read<AuthProvider>().user?.uid;
                    if (userId == null) return;

                    await questProvider.completeQuest(userId, questId);
                    await playerProvider.addExperience(userId, 50);
                    await playerProvider.addGold(userId, 100);
                  },
                  onQuestTap: (quest) {
                    Navigator.of(context).pushNamed('/quest/details', arguments: quest);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateQuestPage(),
            ),
          );
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),
    );
  }
} 