import 'package:flutter/material.dart';

/// Bouton avec style fantasy et animations fluides
class FantasyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? glowColor;
  final bool pulsing;
  final double? width;

  const FantasyButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.glowColor,
    this.pulsing = true,
    this.width,
  });

  @override
  State<FantasyButton> createState() => _FantasyButtonState();
}

class _FantasyButtonState extends State<FantasyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat();

      _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.pulsing) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF1AA7EC);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: widget.pulsing ? _glowAnimation : const AlwaysStoppedAnimation(0.6),
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    glowColor.withOpacity(0.8),
                    glowColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: glowColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(widget.pulsing ? _glowAnimation.value : 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

