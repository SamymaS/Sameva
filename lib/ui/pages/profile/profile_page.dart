import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';
import '../../widgets/figma/fantasy_card.dart';
import '../home/widgets/player_stats_card.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final authUser = context.watch<AuthProvider>().user;
    // Supabase User n'a pas displayName, on utilise userMetadata ou email
    final username = authUser?.userMetadata?['display_name'] as String? ?? 
                     authUser?.userMetadata?['name'] as String? ?? 
                     (authUser?.email?.split('@').first ?? 'Héros');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le Hall des Héros'), // Selon pages.md
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundNightBlue,
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
                      child: Icon(Icons.person, color: AppColors.primaryTurquoise, size: 48),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryTurquoise,
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
          // Section Succès/Hauts-Faits (selon pages.md)
          FantasyCard(
            title: 'Succès et Hauts-Faits',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Médailles à débloquer',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Afficher les succès débloqués
                  Text(
                    'Bientôt disponible',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Section Historique (selon pages.md)
          FantasyCard(
            title: 'Historique des Activités',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // TODO: Afficher l'historique des activités
                  Text(
                    'Bientôt disponible',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
