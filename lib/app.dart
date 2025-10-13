import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'pages/root_shell.dart';
import 'pages/settings/settings_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/rewards/rewards_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/quest/quest_detail_page.dart';
import 'core/providers/quest_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sameva',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: _LaunchDecider(),
          onGenerateRoute: (settings) {
            WidgetBuilder builder;
            Route<dynamic> buildWithTransition(Widget page, {Offset begin = const Offset(0.0, 0.03)}) {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (_, __, ___) => page,
                transitionsBuilder: (_, animation, __, child) {
                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              );
            }

            switch (settings.name) {
              case '/':
                return buildWithTransition(const RootShell());
              case '/login':
                return buildWithTransition(const LoginPage());
              case '/rewards':
                return buildWithTransition(const RewardsPage());
              case '/profile':
                return buildWithTransition(const ProfilePage());
              case '/settings':
                return buildWithTransition(const SettingsPage());
              case '/onboarding':
                return buildWithTransition(const OnboardingPage());
              case '/quest/details':
                final args = settings.arguments;
                if (args is Quest) {
                  return buildWithTransition(QuestDetailPage(quest: args));
                }
                return buildWithTransition(const Scaffold(body: Center(child: Text('Aucune quête à afficher'))));
              default:
                return buildWithTransition(const Scaffold(body: Center(child: Text('Page introuvable'))));
            }
          },
        );
      },
    );
  }
} 

class _LaunchDecider extends StatelessWidget {
  Future<bool> _hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_onboarded') ?? false;
  }

  const _LaunchDecider();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasOnboarded(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasOnboarded = snapshot.data ?? false;
        if (!hasOnboarded) {
          return const OnboardingPage();
        }
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isAuthenticated) {
              return const RootShell();
            }
            return const LoginPage();
          },
        );
      },
    );
  }
}