import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Bouton stylisé avec support pour icônes et assets
class FantasyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? assetIcon; // Chemin vers une image asset
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final bool isOutlined;
  final bool isLoading;

  const FantasyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.assetIcon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.isOutlined = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (assetIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Image.asset(
                assetIcon!,
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            )
          else if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: 20),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
        ],
      ],
    );

    final button = Container(
      width: width,
      height: height ?? 50,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor,
          width: 2,
        ),
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: bgColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(child: content),
    );

    if (onPressed == null || isLoading) {
      return Opacity(opacity: 0.6, child: button);
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: button,
    );
  }
}




