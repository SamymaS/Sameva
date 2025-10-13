import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Apparence', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ThemeModeSelector(currentMode: themeProvider.themeMode, onChanged: (mode) => themeProvider.setThemeMode(mode)),
          const SizedBox(height: 24),
          Text('Compte', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Se déconnecter'),
              onTap: () async {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('À propos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.info),
              title: Text('Sameva v0.1.0'),
              subtitle: Text('Une application de gestion de quêtes gamifiée'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode; final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (m) { if (m != null) onChanged(m); },
            title: const Text('Système'),
          ),
          const Divider(height: 0),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (m) { if (m != null) onChanged(m); },
            title: const Text('Clair'),
          ),
          const Divider(height: 0),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (m) { if (m != null) onChanged(m); },
            title: const Text('Sombre'),
          ),
        ],
      ),
    );
  }
}
