import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../../presentation/providers/auth_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    // P1.1 : migré de shared_preferences vers Hive (settings box déjà ouvert)
    await Hive.box('settings').put('has_onboarded', true);

    if (!mounted) return;
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildSlide(
        title: 'Transforme ta vie en aventure',
        subtitle: 'Définis des quêtes, gagne de l\'XP et progresse chaque jour',
        icon: Icons.auto_awesome,
        color: AppColors.primaryTurquoise,
      ),
      _buildSlide(
        title: 'Des quêtes épiques',
        subtitle: 'Crée des objectifs clairs et motivants avec des récompenses',
        icon: Icons.assignment_turned_in,
        color: AppColors.secondaryViolet,
      ),
      _buildSlide(
        title: 'Progresse et gagne des récompenses',
        subtitle: 'Obtiens de l\'XP, des pièces et des objets en accomplissant tes quêtes',
        icon: Icons.emoji_events,
        color: AppColors.gold,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: _currentPage == i
                      ? AppColors.primaryTurquoise
                      : AppColors.textMuted.withValues(alpha: 0.5),
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
                    : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut),
                child: Text(
                    _currentPage == pages.length - 1 ? 'Commencer' : 'Suivant'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
