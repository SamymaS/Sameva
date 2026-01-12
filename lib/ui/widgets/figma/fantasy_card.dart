import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Widget Card inspiré des composants Figma
/// Équivalent au composant Card React dans assets/components/ui/card.tsx
class FantasyCard extends StatelessWidget {
  final Widget? child;
  final Widget? header;
  final Widget? footer;
  final String? title;
  final String? description;
  final Widget? action;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const FantasyCard({
    super.key,
    this.child,
    this.header,
    this.footer,
    this.title,
    this.description,
    this.action,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundDarkPanel.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: AppColors.inputBorder),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null || title != null || description != null || action != null)
            _CardHeader(
              header: header,
              title: title,
              description: description,
              action: action,
            ),
          if (child != null)
            Padding(
              padding: padding ?? const EdgeInsets.all(24),
              child: child!,
            ),
          if (footer != null) _CardFooter(footer!),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Widget? header;
  final String? title;
  final String? description;
  final Widget? action;

  const _CardHeader({
    this.header,
    this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    if (header != null) return header!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
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

class _CardFooter extends StatelessWidget {
  final Widget footer;

  const _CardFooter(this.footer);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: footer,
    );
  }
}

