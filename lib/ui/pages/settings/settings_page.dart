import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/theme_provider.dart';

/// Paramètres — Hick (peu d’options), Jakob (ListTile standard).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Thème sombre'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().themeMode == ThemeMode.dark,
              onChanged: (v) {
                context.read<ThemeProvider>().setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            subtitle: const Text('Sameva · Validez vos quêtes'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sameva',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Validation de quêtes par preuve visuelle.',
              );
            },
          ),
        ],
      ),
    );
  }
}
