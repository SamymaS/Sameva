import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Panneau glassmorphism pour contenir du contenu scrollable
/// Style "Magie Minimaliste" selon UX_UI_REFACTORING.md
class MinimalistPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleAction;
  final EdgeInsets? padding;
  final Color? borderColor;
  final bool showTopBorder;

  const MinimalistPanel({
    super.key,
    required this.child,
    this.title,
    this.titleAction,
    this.padding,
    this.borderColor,
    this.showTopBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? AppColors.primaryTurquoise;

    return Container(
      decoration: BoxDecoration(
        // Glassmorphism : Fond sombre translucide
        color: AppColors.backgroundNightBlue.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: defaultBorderColor.withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
        // Inner glow subtil
        boxShadow: [
          BoxShadow(
            color: defaultBorderColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          if (title != null || titleAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (titleAction != null) titleAction!,
                ],
              ),
            ),
          Expanded(
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}






