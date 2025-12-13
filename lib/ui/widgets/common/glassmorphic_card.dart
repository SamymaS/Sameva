import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget Glassmorphic Card - Effet de verre dépoli
/// Basé sur le design Figma avec backdrop blur
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.all(16.0);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(24.0);
    final defaultBorderColor = borderColor ?? Colors.white.withOpacity(0.2);
    final defaultBgColor = backgroundColor ?? Colors.white.withOpacity(0.1);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: defaultBgColor,
        borderRadius: defaultBorderRadius,
        border: Border.all(
          color: defaultBorderColor,
          width: borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: defaultPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

