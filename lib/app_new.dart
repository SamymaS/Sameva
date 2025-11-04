import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/home/new_home_page.dart';
import 'pages/market/market_page.dart';
import 'pages/invocation/invocation_page.dart';
import 'pages/avatar/avatar_page.dart';
import 'widgets/transitions/custom_transitions.dart';
import 'widgets/logo/sameva_logo.dart';

final theme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0F18),
  textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFF59E0B), // accent doré
    brightness: Brightness.dark,
  ),
);

class SamevaApp extends StatefulWidget {
  const SamevaApp({super.key});

  @override
  State<SamevaApp> createState() => _SamevaAppState();
}

class _SamevaAppState extends State<SamevaApp> {
  int index = 0;
  final pages = const [
    NewHomePage(),
    MarketPage(),
    InvocationPage(),
    AvatarPage(),
    // MiniGamePage(), // à activer quand prêt
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sameva',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
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
              key: ValueKey<int>(index),
              child: pages[index],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF111624),
          indicatorColor: const Color(0x33569CF6),
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.store), label: 'Marché'),
            NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Invocation'),
            NavigationDestination(icon: Icon(Icons.face_retouching_natural), label: 'Avatar'),
          ],
        ),
      ),
    );
  }
}

