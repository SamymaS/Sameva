import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'auth_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (isAuthenticated) {
      // Aller à la shell principale
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } else {
      // Aller à la page de connexion
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildSlide(
        title: 'Transforme ta vie en aventure',
        subtitle: 'Définis des quêtes, gagne de l\'XP et progresse chaque jour',
        asset: 'assets/animations/rpg_logo.json',
      ),
      _buildSlide(
        title: 'Des quêtes épiques',
        subtitle: 'Crée des objectifs clairs et motivants avec des récompenses',
        asset: 'assets/animations/rpg_loading.json',
      ),
      _buildSlide(
        title: 'Un univers pastel, fluide et motivant',
        subtitle: 'Des animations douces et un design qui donne envie d\'agir',
        asset: 'assets/animations/loading.json',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Ignorer'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: pages.length,
              itemBuilder: (_, i) => pages[i],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: _currentPage == i ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentPage == pages.length - 1
                    ? _finishOnboarding
                    : () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(_currentPage == pages.length - 1 ? 'Commencer' : 'Suivant'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({required String title, required String subtitle, required String asset}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(asset, width: 220, height: 220),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
