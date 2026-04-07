import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/leaderboard_view_model.dart';
import '../../theme/app_colors.dart';

/// Page classement global des joueurs.
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LeaderboardRepository>();
    final userId = context.read<AuthViewModel>().userId ?? '';

    return ChangeNotifierProvider(
      create: (_) => LeaderboardViewModel(repo)..load(userId),
      child: const _LeaderboardContent(),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeaderboardViewModel>();
    final userId = context.read<AuthViewModel>().userId ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Classement',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryVioletLight,
        backgroundColor: AppColors.backgroundDarkPanel,
        onRefresh: () => vm.refresh(userId),
        child: _buildBody(context, vm, userId),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, LeaderboardViewModel vm, String userId) {
    if (vm.loading && vm.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryVioletLight),
      );
    }

    if (vm.error != null && vm.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => vm.refresh(userId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryViolet),
              ),
            ],
          ),
        ),
      );
    }

    if (vm.entries.isEmpty) {
      return Center(
        child: Text(
          'Aucun joueur pour le moment.',
          style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 15),
        ),
      );
    }

    // Podium (top 3) + liste
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: vm.entries.length + 1, // +1 pour le header podium
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildPodium(vm.entries.take(3).toList(), userId);
        }
        final entry = vm.entries[index - 1];
        final isCurrentUser = entry.userId == userId;
        return _LeaderboardRow(
          entry: entry,
          isCurrentUser: isCurrentUser,
        );
      },
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3, String userId) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2e place
          if (top3.length > 1)
            _PodiumStand(entry: top3[1], height: 80, userId: userId),
          const SizedBox(width: 8),
          // 1re place
          _PodiumStand(entry: top3[0], height: 110, userId: userId),
          const SizedBox(width: 8),
          // 3e place
          if (top3.length > 2)
            _PodiumStand(entry: top3[2], height: 60, userId: userId),
        ],
      ),
    );
  }
}

// ── Podium ───────────────────────────────────────────────────────────────────

class _PodiumStand extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final String userId;

  const _PodiumStand({
    required this.entry,
    required this.height,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = entry.userId == userId;
    final medalColors = [
      AppColors.gold,
      AppColors.rarityCommon,
      const Color(0xFFCD7F32),
    ];
    final medal = ['🥇', '🥈', '🥉'][entry.rank - 1];
    final color = medalColors[entry.rank - 1];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: isCurrentUser
                  ? AppColors.primaryVioletLight
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Niv. ${entry.level}',
            style: GoogleFonts.nunito(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: GoogleFonts.nunito(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne de classement ──────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryViolet.withValues(alpha: 0.15)
            : AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primaryVioletLight
              : AppColors.inputBorder,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rang
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.nunito(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),

          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: GoogleFonts.nunito(
                    color: isCurrentUser
                        ? AppColors.primaryVioletLight
                        : AppColors.textPrimary,
                    fontWeight:
                        isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (isCurrentUser)
                  Text(
                    'Toi',
                    style: GoogleFonts.nunito(
                      color: AppColors.primaryVioletLight,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Niveau
          _StatChip(
            icon: Icons.star_rounded,
            color: AppColors.gold,
            label: 'Niv. ${entry.level}',
          ),
          const SizedBox(width: 8),

          // Streak
          if (entry.streak > 0)
            _StatChip(
              icon: Icons.local_fire_department_rounded,
              color: AppColors.coralRare,
              label: '${entry.streak}j',
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
