import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withBackground;
  final bool withShadow;

  const AppLogo({
    super.key,
    this.size = 100,
    this.withBackground = true,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Image.asset(
      'assets/images/sameva_logo.png',
      width: size * 0.8,
      height: size * 0.8,
      fit: BoxFit.contain,
    );

    if (withBackground) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: withShadow ? const [AppStyles.softShadow] : null,
        ),
        child: Center(child: logo),
      );
    }

    return logo;
  }
}
