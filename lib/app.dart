import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/theme_view_model.dart';
import 'ui/pages/auth/login_page.dart';
import 'ui/pages/onboarding/onboarding_page.dart';
import 'ui/pages/auth/register_page.dart';
import 'ui/pages/quest/create_quest_page.dart';
import 'ui/pages/quest/quest_validation_page.dart';
import 'ui/pages/quest/quests_list_page.dart';
import 'ui/pages/profile/profile_page.dart';
import 'ui/pages/rewards/rewards_page.dart';
import 'ui/pages/settings/settings_page.dart';
import 'ui/pages/home/sanctuary_page.dart';
import 'ui/pages/inventory/inventory_page.dart';
import 'ui/pages/market/market_page.dart';
import 'ui/pages/cat/cat_page.dart';
import 'ui/widgets/common/dock_bar.dart';
import 'ui/theme/app_theme.dart';
import 'data/models/quest_model.dart';

/// Sameva — navigation 5 pages avec DockBar flottant + swipe horizontal.
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
    CatPage(),
    MarketPage(),
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
    return Consumer<ThemeViewModel>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Sameva',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => const LoginPage(),
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
          home: Consumer<AuthViewModel>(
            builder: (context, authProvider, _) {
              // Afficher l'onboarding une seule fois (flag Hive 'has_onboarded')
              final hasOnboarded =
                  Hive.box('settings').get('has_onboarded', defaultValue: false) as bool;
              if (!hasOnboarded) {
                return const OnboardingPage();
              }
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
    // viewPadding.bottom est stable même quand le clavier est ouvert,
    // contrairement à padding.bottom qui peut devenir 0.
    final navBarHeight = MediaQuery.viewPaddingOf(context).bottom;
    const dockBarHeight = 68.0;

    return Scaffold(
      // Empêche le Scaffold de redimensionner le body quand le clavier s'ouvre
      // (le keyboard est géré par chaque page individuellement).
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Contenu des pages : réserve l'espace pour la DockBar + barre Android
          Padding(
            padding: EdgeInsets.only(bottom: dockBarHeight + navBarHeight),
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: _pages,
            ),
          ),
          // DockBar flottante en bas — gère elle-même son padding de barre sys
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
