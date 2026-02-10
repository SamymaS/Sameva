import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/quest_provider.dart';
import 'domain/services/health_regeneration_service.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/home/sanctuary_page.dart';
import 'ui/pages/quest/quests_list_page.dart';
import 'ui/pages/inventory/inventory_page.dart';
import 'ui/pages/avatar/avatar_page.dart';
import 'ui/pages/market/market_page.dart';
import 'ui/pages/invocation/invocation_page.dart';
import 'ui/pages/minigame/minigame_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/pages/quest/fantasy_create_quest_page.dart';
import 'ui/widgets/minimalist/floating_dock.dart';
import 'ui/widgets/minimalist/floating_fab.dart';
import 'ui/theme/app_theme.dart';

final theme = AppTheme.dark();

class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int _currentIndex = 0;

  // Pages selon pages.md : [Maison] Home, [Parchemin] Quêtes, [Sac] Inventaire,
  // [Épée] Customisation, [Boutique] Marché, [✨] Invocation, [Manette] Mini-Jeux, [Tête] Profil
  final List<Widget> _pages = [
    const SanctuaryPage(), // [Maison] Home - Index 0
    const QuestsListPage(), // [Parchemin] Quêtes - Index 1
    const InventoryPage(), // [Sac] Inventaire - Index 2
    const AvatarPage(), // [Épée] Customisation (Miroir des Âmes) - Index 3
    const MarketPage(), // [Boutique] Marché - Index 4
    const InvocationPage(), // [✨] Invocation (Gacha) - Index 5
    const MiniGamePage(), // [Manette] Mini-Jeux - Index 6
    const ProfilePage(), // [Tête] Profil (Hall des Héros) - Index 7
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Quêtes',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Sac',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_martial_arts_outlined),
      selectedIcon: Icon(Icons.sports_martial_arts),
      label: 'Custom',
    ),
    NavigationDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store),
      label: 'Marché',
    ),
    NavigationDestination(
      icon: Icon(Icons.sports_esports_outlined),
      selectedIcon: Icon(Icons.sports_esports),
      label: 'Jeux',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profil',
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
          return _AuthenticatedShell(
            currentIndex: _currentIndex,
            pages: _pages,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}

/// Shell authentifié qui applique HealthRegeneration au premier chargement
class _AuthenticatedShell extends StatefulWidget {
  final int currentIndex;
  final List<Widget> pages;
  final ValueChanged<int> onIndexChanged;

  const _AuthenticatedShell({
    required this.currentIndex,
    required this.pages,
    required this.onIndexChanged,
  });

  @override
  State<_AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<_AuthenticatedShell> {
  bool _healthEffectsApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyHealthEffects();
    });
  }

  Future<void> _applyHealthEffects() async {
    if (_healthEffectsApplied) return;
    _healthEffectsApplied = true;

    final authProvider = context.read<AuthProvider>();
    final playerProvider = context.read<PlayerProvider>();
    final questProvider = context.read<QuestProvider>();
    final userId = authProvider.userId ?? '';

    if (userId.isEmpty || playerProvider.stats == null) return;

    await HealthRegenerationService.applyHealthEffects(
      userId: userId,
      playerProvider: playerProvider,
      questProvider: questProvider,
    );
    await HealthRegenerationService.applyMoralEffects(
      userId: userId,
      playerProvider: playerProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenu des pages avec animations + padding pour le dock
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 90, // Safe area + dock (70px) + marge (20px)
            ),
            child: AnimatedSwitcher(
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
                key: ValueKey<int>(widget.currentIndex),
                child: widget.pages[widget.currentIndex],
              ),
            ),
          ),
          // Dock Flottant avec FAB central (toujours au-dessus)
          FloatingDock(
            currentIndex: widget.currentIndex,
            onItemSelected: widget.onIndexChanged,
            centerFab: FloatingFAB(
              icon: Icons.add,
              tooltip: 'Nouvelle Quête',
              onPressed: () {
                Navigator.of(context).pushNamed('/create-quest');
              },
            ),
          ),
        ],
      ),
    );
  }
}
