import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget Badge inspiré des composants Figma
/// Équivalent au composant Badge React dans assets/components/ui/badge.tsx
enum BadgeVariant {
  default_,
  secondary,
  destructive,
  outline,
}

class FantasyBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets? padding;

  const FantasyBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.default_,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
  });

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;
    switch (variant) {
      case BadgeVariant.default_:
        return AppColors.primary;
      case BadgeVariant.secondary:
        return AppColors.accent;
      case BadgeVariant.destructive:
        return AppColors.error;
      case BadgeVariant.outline:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    if (textColor != null) return textColor!;
    switch (variant) {
      case BadgeVariant.default_:
        return AppColors.primaryForeground;
      case BadgeVariant.secondary:
        return AppColors.accentForeground;
      case BadgeVariant.destructive:
        return Colors.white;
      case BadgeVariant.outline:
        return AppColors.textPrimary;
    }
  }

  Border? get _border {
    if (variant == BadgeVariant.outline) {
      return Border.all(color: AppColors.border);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: _border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}




