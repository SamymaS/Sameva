import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HerosDeTaVieApp());
}

class HerosDeTaVieApp extends StatelessWidget {
  const HerosDeTaVieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Héros de ta Vie',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Sans',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
} 
