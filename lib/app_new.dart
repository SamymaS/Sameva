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

/// Sameva — navigation 8 pages avec DockBar flottant + swipe horizontal.
class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int _currentIndex = 0;
  late final PageController _pageController;

  // Pages enveloppées dans _KeepAlivePage pour préserver leur état pendant le swipe
  late final List<Widget> _pages;

  static const _rawPages = <Widget>[
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
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pages = _rawPages.map((p) => _KeepAlivePage(child: p)).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

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
              return _buildHome(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Stack(
        children: [
          // Padding pour que le contenu ne passe pas derrière la DockBar
          Padding(
            padding: EdgeInsets.only(bottom: 64 + bottomInset),
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: _pages,
            ),
          ),
          // DockBar flottante
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DockBar(
              currentIndex: _currentIndex,
              onTap: _goToPage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Préserve l'état d'une page même quand elle sort du viewport du PageView.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
