import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/services/achievement_service.dart';
import '../../../domain/services/activity_log_service.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/notification_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/settings_view_model.dart';
import '../../../presentation/view_models/theme_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../profile/achievements_page.dart';

/// Paramètres de l'application.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= SettingsViewModel(
      context.read<ThemeViewModel>(),
      context.read<NotificationViewModel>(),
      context.read<PlayerViewModel>(),
      context.read<AuthViewModel>(),
    );
  }

  @override
  void dispose() {
    _vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsViewModel>.value(
      value: _vm!,
      child: Scaffold(
        backgroundColor: AppColors.backgroundNightBlue,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundNightBlue,
          title: const Text(
            'Paramètres',
            style: TextStyle(
                color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const _SectionHeader('Apparence'),
            _ThemeTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _SectionHeader('Notifications'),
            _NotificationTimeTile(),
            _StreakNotifTile(),
            _DeadlineNotifTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _SectionHeader('Progression'),
            _AchievementsTile(),
            _ExportActivityTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _SectionHeader('Joueur'),
            _ResetPlayerTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _SectionHeader('Application'),
            _AboutTile(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsViewModel>().isDark;
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: AppColors.primaryTurquoise,
      ),
      title: const Text('Thème sombre',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        isDark ? 'Activé' : 'Désactivé',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Switch(
        value: isDark,
        activeThumbColor: AppColors.primaryTurquoise,
        onChanged: (v) => context.read<SettingsViewModel>().setDarkMode(v),
      ),
    );
  }
}

class _NotificationTimeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.notifications_outlined,
          color: AppColors.primaryTurquoise),
      title: const Text('Rappel quotidien',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        'Rappel à ${vm.reminderTimeLabel}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: vm.reminderHour,
            minute: vm.reminderMinute,
          ),
          helpText: "Heure du rappel quotidien",
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryTurquoise,
                surface: AppColors.backgroundDarkPanel,
              ),
            ),
            child: child!,
          ),
        );
        if (picked == null) return;
        if (!context.mounted) return;
        await context
            .read<SettingsViewModel>()
            .setReminderTime(picked.hour, picked.minute);
        if (!context.mounted) return;
        AppNotification.show(
          context,
          message: 'Rappel mis à jour : ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        );
      },
    );
  }
}

class _ResetPlayerTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.restart_alt, color: AppColors.error),
      title: const Text('Réinitialiser le joueur',
          style: TextStyle(color: AppColors.error)),
      subtitle: const Text(
        'Remet le niveau à 1 et réduit l\'or de moitié.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundDarkPanel,
            title: const Text('Confirmer la réinitialisation',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text(
              'Votre niveau, XP et HP seront réinitialisés. '
              'Votre or sera réduit de moitié. Les achievements et '
              'le meilleur streak sont conservés.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Réinitialiser',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        if (!context.mounted) return;
        await context.read<SettingsViewModel>().resetPlayer();
        if (!context.mounted) return;
        AppNotification.show(context, message: 'Joueur réinitialisé.');
      },
    );
  }
}

class _StreakNotifTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.local_fire_department_outlined,
          color: AppColors.warning),
      title: const Text('Rappel de série',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: const Text(
        'Notification à 20h si aucune quête complétée.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Switch(
        value: vm.streakNotifEnabled,
        activeThumbColor: AppColors.warning,
        onChanged: (v) => context.read<SettingsViewModel>().setStreakNotif(v),
      ),
    );
  }
}

class _DeadlineNotifTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.alarm_outlined,
          color: AppColors.coralRare),
      title: const Text('Rappels d\'échéance',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: const Text(
        'Notification 1h avant la deadline de chaque quête.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Switch(
        value: vm.deadlineNotifEnabled,
        activeThumbColor: AppColors.coralRare,
        onChanged: (v) => context.read<SettingsViewModel>().setDeadlineNotif(v),
      ),
    );
  }
}

class _AchievementsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unlocked = AchievementService.getUnlocked();
    final total = AchievementService.all.length;
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.emoji_events_outlined, color: AppColors.gold),
      title: const Text('Succès',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        '${unlocked.length} / $total débloqués',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AchievementsPage()),
      ),
    );
  }
}

class _ExportActivityTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.download_outlined,
          color: AppColors.primaryTurquoise),
      title: const Text('Exporter l\'activité',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: const Text(
        'Partager le journal d\'activité en texte.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.ios_share_outlined,
          color: AppColors.textMuted, size: 18),
      onTap: () {
        final log = ActivityLogService.getLog();
        if (log.isEmpty) {
          AppNotification.show(context, message: 'Aucune activité à exporter.');
          return;
        }
        final lines = log.map((e) {
          final d = e.date;
          final date =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          final sub = e.subtitle != null ? ' · ${e.subtitle}' : '';
          return '[$date] ${e.title}$sub';
        }).join('\n');
        Share.share('Journal d\'activité Sameva\n\n$lines');
      },
    );
  }
}

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.info_outline, color: AppColors.primaryTurquoise),
      title: const Text('À propos',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: const Text('Sameva v1.0.0 · Validez vos quêtes',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      onTap: () => showAboutDialog(
        context: context,
        applicationName: 'Sameva',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.shield_outlined,
            color: AppColors.primaryTurquoise, size: 40),
        applicationLegalese:
            '© 2026 Sameva · Gamifiez votre quotidien.\nValidation de quêtes par preuve visuelle.',
      ),
    );
  }
}
