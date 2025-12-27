import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Bouton minimaliste avec style glassmorphism
/// Style "Magie Minimaliste" selon UX_UI_REFACTORING.md
class MinimalistButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isOutlined;
  final double? width;
  final EdgeInsets? padding;

  const MinimalistButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isOutlined = true,
    this.width,
    this.padding,
  });

  @override
  State<MinimalistButton> createState() => _MinimalistButtonState();
}

class _MinimalistButtonState extends State<MinimalistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primaryTurquoise;
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : _handleTapDown,
      onTapUp: isDisabled ? null : _handleTapUp,
      onTapCancel: isDisabled ? null : _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_scaleController.value * 0.02), // Scale subtil au press
            child: Container(
              width: widget.width,
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.isOutlined
                    ? Colors.transparent
                    : buttonColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? Colors.white.withOpacity(0.1)
                      : buttonColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: _isPressed && !isDisabled
                    ? [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: isDisabled
                          ? Colors.white.withOpacity(0.3)
                          : buttonColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}





