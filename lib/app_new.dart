import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/auth/register_page.dart';
import 'ui/pages/quest/create_quest_page.dart';
import 'ui/pages/quest/quest_validation_page.dart';
import 'ui/pages/quest/quests_list_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/rewards/rewards_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/theme/app_theme.dart';
import 'data/models/quest_model.dart';

/// Sameva — MVVM, UX (Fitts, Hick, Jakob, Miller, Goal Gradient), PWA-ready.
/// 6 pages : Auth | Mes Quêtes | Création | Validation | Récompenses | Profil
class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const QuestsListPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Sameva',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          routes: {
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => const SettingsPage(),
            '/quests': (context) => const QuestsListPage(),
            '/create-quest': (context) => const CreateQuestPage(),
            '/rewards': (context) => const RewardsPage(),
            '/register': (context) => const RegisterPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/quest/validate' && settings.arguments is Quest) {
              return MaterialPageRoute<void>(
                builder: (_) => QuestValidationPage(quest: settings.arguments! as Quest),
              );
            }
            return null;
          },
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isAuthenticated) {
                return const LoginPage();
              }
              return _buildHome();
            },
          ),
        );
      },
    );
  }

  Widget _buildHome() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Mes Quêtes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/create-quest'),
        icon: const Icon(Icons.add),
        label: const Text('Créer une quête'),
      ),
    );
  }
}
