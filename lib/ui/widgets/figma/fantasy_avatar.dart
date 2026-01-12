import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget Avatar inspiré des composants Figma
/// Équivalent au composant Avatar React dans assets/components/ui/avatar.tsx
class FantasyAvatar extends StatelessWidget {
  final String? imageUrl;
  final Widget? fallback;
  final String? fallbackText;
  final double size;
  final Color? backgroundColor;

  const FantasyAvatar({
    super.key,
    this.imageUrl,
    this.fallback,
    this.fallbackText,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.textMuted,
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    if (fallback != null) {
      return fallback!;
    }
    if (fallbackText != null) {
      return Center(
        child: Text(
          fallbackText!.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: AppColors.textSecondary,
    );
  }
}









