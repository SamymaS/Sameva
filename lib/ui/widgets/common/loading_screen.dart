import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
<<<<<<< HEAD:lib/core/widgets/loading_screen.dart
import '../../theme/app_theme.dart';
=======
import 'app_theme.dart';
>>>>>>> 8b32b3faebf56148495e42cbb9f47ffda8173a99:lib/ui/widgets/common/loading_screen.dart

class RPGLoadingScreen extends StatelessWidget {
  final String? message;

  const RPGLoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de chargement
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Lottie.asset(
                'assets/animations/rpg_loading.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            // Message de chargement
            if (message != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 