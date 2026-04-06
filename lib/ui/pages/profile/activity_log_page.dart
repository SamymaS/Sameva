import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../domain/services/activity_log_service.dart';
import '../../theme/app_colors.dart';

class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final log = ActivityLogService.getLog();

    return Scaffold(
      backgroundColor: AppColors.backgroundNightCosmos,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightCosmos,
        title: Text(
          'Historique',
          style: GoogleFonts.nunito(
            color: AppColors.primaryVioletLight,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: log.isEmpty
          ? Center(
              child: Text(
                'Aucune activité pour l\'instant.\nComplète ta première quête !',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: AppColors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: log.length,
              itemBuilder: (_, i) => _EntryTile(entry: log[i]),
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final ActivityLogEntry entry;

  const _EntryTile({required this.entry});

  Color get _color => switch (entry.type) {
        ActivityType.quest       => AppColors.primaryTurquoise,
        ActivityType.levelUp     => AppColors.gold,
        ActivityType.item        => AppColors.rarityEpic,
        ActivityType.achievement => AppColors.rarityLegendary,
        ActivityType.streak      => AppColors.warning,
      };

  IconData get _icon => switch (entry.type) {
        ActivityType.quest       => Icons.check_circle_outline,
        ActivityType.levelUp     => Icons.trending_up,
        ActivityType.item        => Icons.inventory_2_outlined,
        ActivityType.achievement => Icons.emoji_events_outlined,
        ActivityType.streak      => Icons.local_fire_department,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final dateLabel = _formatDate(entry.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (entry.subtitle != null)
                  Text(
                    entry.subtitle!,
                    style: GoogleFonts.nunito(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            dateLabel,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes}min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('d MMM', 'fr').format(date);
  }
}
