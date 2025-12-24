import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/minimalist/hud_header.dart';
import '../../widgets/minimalist/minimalist_card.dart';
import '../../widgets/magical/animated_background.dart';
import '../../widgets/magical/glowing_card.dart';
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
    final stats = playerProvider.stats;

    return Scaffold(
      body: AnimatedMagicalBackground(
        child: Stack(
          children: [
            // Header HUD
          HUDHeader(
            level: stats?.level ?? 1,
            experience: stats?.experience ?? 0,
            maxExperience: playerProvider.experienceForLevel(stats?.level ?? 1),
            healthPoints: stats?.healthPoints ?? 100,
            maxHealthPoints: stats?.maxHealthPoints ?? 100,
            gold: stats?.gold ?? 0,
            crystals: stats?.crystals ?? 0,
            onSettingsTap: () {
              // Navigation vers settings
            },
          ),
          // Contenu
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), // Padding en haut pour le header, en bas pour le dock
              children: [
                // Titre de page centré
                Center(
                  child: Text(
                    'Le Hall des Héros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cinzel',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Avatar avec bouton d'édition
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          color: AppColors.primaryTurquoise,
                          size: 48,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryTurquoise,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryTurquoise.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Username
                Center(
                  child: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Titre/Rôle
                Center(
                  child: Text(
                    'Aventurier',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Carte de stats
                const PlayerStatsCard(),
                const SizedBox(height: 16),
                // Section Succès/Hauts-Faits
                GlowingCard(
                  glowColor: AppColors.primaryTurquoise,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Succès et Hauts-Faits',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Médailles à débloquer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bientôt disponible',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Section Historique
                GlowingCard(
                  glowColor: AppColors.secondaryViolet,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historique des Activités',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bientôt disponible',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
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
