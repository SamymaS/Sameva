import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Remplacer par votre animation Lottie
            Lottie.asset(
              'assets/animations/rpg_loading.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'SAMEVA',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
            ).animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms),
            const SizedBox(height: 16),
            Text(
              'Transformez votre vie en aventure',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ).animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
} 