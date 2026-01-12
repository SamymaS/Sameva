import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../home/widgets/player_stats_card.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final username = authUser?.displayName ?? (authUser?.email?.split('@').first ?? 'Héros');

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: AppColors.primary, size: 48),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(username, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Aventurier', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const PlayerStatsCard(),
          const SizedBox(height: 16),
          _ProfileTile(icon: Icons.emoji_events_outlined, title: 'Succès', subtitle: 'Bientôt disponible'),
          _ProfileTile(icon: Icons.history_outlined, title: 'Historique', subtitle: 'Bientôt disponible'),
          _ProfileTile(icon: Icons.palette_outlined, title: 'Personnalisation', subtitle: 'Bientôt disponible'),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _ProfileTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {},
      ),
    );
  }
}
