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
import 'ui/pages/home/sanctuary_page.dart';
import 'ui/pages/inventory/inventory_page.dart';
import 'ui/pages/avatar/avatar_page.dart';
import 'ui/pages/market/market_page.dart';
import 'ui/pages/invocation/invocation_page.dart';
import 'ui/pages/minigames/minigames_page.dart';
import 'ui/widgets/common/dock_bar.dart';
import 'ui/theme/app_theme.dart';
import 'data/models/quest_model.dart';

/// Sameva — navigation 8 pages avec DockBar flottant.
class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int _currentIndex = 0;

  static const _pages = [
    SanctuaryPage(),
    QuestsListPage(),
    InventoryPage(),
    AvatarPage(),
    MarketPage(),
    InvocationPage(),
    MinigamesPage(),
    ProfilePage(),
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
            if (settings.name == '/quest/validate' &&
                settings.arguments is Quest) {
              return MaterialPageRoute<void>(
                builder: (_) =>
                    QuestValidationPage(quest: settings.arguments! as Quest),
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 64),
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DockBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/create-quest'),
        backgroundColor: const Color(0xFF4FD1C5),
        child: const Icon(Icons.add),
      ),
    );
  }
}
