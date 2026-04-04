import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/view_models/notification_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/theme_view_model.dart';
import '../../theme/app_colors.dart';

/// Paramètres de l'application.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _SectionHeader('Apparence'),
          _ThemeTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader('Notifications'),
          _NotificationTimeTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader('Joueur'),
          _ResetPlayerTile(),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader('Application'),
          _AboutTile(),
        ],
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
    final isDark = context.watch<ThemeViewModel>().themeMode == ThemeMode.dark;
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
        activeColor: AppColors.primaryTurquoise,
        onChanged: (v) {
          context
              .read<ThemeViewModel>()
              .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }
}

class _NotificationTimeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationViewModel>();

    return ListTile(
      tileColor: AppColors.backgroundDarkPanel,
      leading: const Icon(Icons.notifications_outlined,
          color: AppColors.primaryTurquoise),
      title: const Text('Rappel quotidien',
          style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(
        'Rappel à ${notifProvider.reminderTimeLabel}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: notifProvider.reminderHour,
            minute: notifProvider.reminderMinute,
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
            .read<NotificationViewModel>()
            .setReminderTime(picked.hour, picked.minute);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rappel mis à jour : ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            ),
          ),
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
        final userId = context.read<AuthViewModel>().userId ?? '';
        await context.read<PlayerViewModel>().resetPlayer(userId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joueur réinitialisé.')),
        );
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
