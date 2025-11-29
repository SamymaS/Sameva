import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Titre stylisé avec support pour icônes et assets
class FantasyTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? assetIcon;
  final TextStyle? textStyle;
  final Color? iconColor;
  final double? iconSize;
  final MainAxisAlignment alignment;

  const FantasyTitle({
    super.key,
    required this.text,
    this.icon,
    this.assetIcon,
    this.textStyle,
    this.iconColor,
    this.iconSize,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            );

    return Row(
      mainAxisAlignment: alignment,
      children: [
        if (assetIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              assetIcon!,
              width: iconSize ?? 32,
              height: iconSize ?? 32,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              size: iconSize ?? 32,
              color: iconColor ?? AppColors.primary,
            ),
          ),
        Flexible(
          child: Text(
            text,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// Titre de section
class SectionTitle extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? action;

  const SectionTitle({
    super.key,
    required this.text,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}




