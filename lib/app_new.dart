import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/home/sanctuary_page.dart';
import 'ui/pages/quest/quests_list_page.dart';
import 'ui/pages/inventory/inventory_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/pages/quest/fantasy_create_quest_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/app_colors.dart';

final theme = AppTheme.dark();

class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int _currentIndex = 0;
  
  // Pages selon le design Figma : Accueil, Quêtes, Sac, Cercle, Réglages
  final List<Widget> _pages = [
    const SanctuaryPage(), // Nouvelle page Sanctuary améliorée
    const QuestsListPage(),
    const InventoryPage(),
    const ProfilePage(), // Cercle/Social (temporairement Profile)
    const SettingsPage(),
  ];
  
  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment),
      label: 'Quêtes',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Sac',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Cercle',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Réglages',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sameva',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routes: {
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/quests': (context) => const QuestsListPage(),
        '/inventory': (context) => const InventoryPage(),
        '/create-quest': (context) => const FantasyCreateQuestPage(),
      },
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Rediriger vers la page de login si l'utilisateur n'est pas connecté
          if (!authProvider.isAuthenticated) {
            return const LoginPage();
          }
          
          // Afficher l'application principale si l'utilisateur est connecté
          return Scaffold(
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curvedAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.03),
                      end: Offset.zero,
                    ).animate(curvedAnimation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _pages[_currentIndex],
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundDeepViolet.withOpacity(0.95),
                    AppColors.backgroundDeepViolet.withOpacity(0.98),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.secondaryViolet.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.secondaryViolet.withOpacity(0.2),
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: _destinations,
                elevation: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}

