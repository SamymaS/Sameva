import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/view_models/profile_view_model.dart';

/// Profil / Historique — Goal Gradient (XP, streak, quêtes), Jakob (ListTile standard).
/// Miller : 5–7 infos max (niveau, XP, or, streak, quêtes, déconnexion).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null && _vm == null) {
      _vm = ProfileViewModel(
        context.read<AuthProvider>(),
        context.read<PlayerProvider>(),
        context.read<QuestProvider>(),
      );
      _vm!.load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<ProfileViewModel>.value(
      value: _vm!,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              tooltip: 'Paramètres',
            ),
          ],
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final level = vm.level ?? 1;
            final experience = vm.experience ?? 0;
            final gold = vm.gold ?? 0;
            final streak = vm.streak;
            final completed = vm.completedCount;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (vm.userEmail != null)
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(vm.userEmail!),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Niveau'),
                  trailing: Text('$level', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up),
                  title: const Text('XP total'),
                  trailing: Text('$experience', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.monetization_on_outlined),
                  title: const Text('Or'),
                  trailing: Text('$gold', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: const Text('Série'),
                  trailing: Text('$streak jour${streak > 1 ? 's' : ''}', style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Quêtes terminées'),
                  trailing: Text('$completed', style: Theme.of(context).textTheme.titleMedium),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Déconnexion'),
                  onTap: () async {
                    await vm.signOut();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
