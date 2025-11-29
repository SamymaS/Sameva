import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Bannière stylisée pour afficher des informations importantes
class FantasyBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? assetIcon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? action;
  final VoidCallback? onTap;

  const FantasyBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.assetIcon,
    this.backgroundColor,
    this.borderColor,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary.withOpacity(0.1);
    final border = borderColor ?? AppColors.primary;

    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (assetIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                assetIcon!,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                icon,
                size: 32,
                color: border,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return content;
  }
}

/// Bannière de succès
class SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const SuccessBanner({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FantasyBanner(
      title: message,
      icon: Icons.check_circle,
      backgroundColor: AppColors.success.withOpacity(0.1),
      borderColor: AppColors.success,
      onTap: onTap,
    );
  }
}

/// Bannière d'avertissement
class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const WarningBanner({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FantasyBanner(
      title: message,
      icon: Icons.warning,
      backgroundColor: AppColors.warning.withOpacity(0.1),
      borderColor: AppColors.warning,
      onTap: onTap,
    );
  }
}

/// Bannière d'information
class InfoBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const InfoBanner({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FantasyBanner(
      title: message,
      icon: Icons.info,
      backgroundColor: AppColors.info.withOpacity(0.1),
      borderColor: AppColors.info,
      onTap: onTap,
    );
  }
}




