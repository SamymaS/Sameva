import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../pages/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

class SamevaApp extends StatelessWidget {
  const SamevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sameva',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      // TODO: Ajouter les routes nommées ici
      // routes: {
      //   '/home': (context) => const HomePage(),
      //   '/profile': (context) => const ProfilePage(),
      //   // etc...
      // },
    );
  }
} 