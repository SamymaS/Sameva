import 'package:flutter/material.dart';

/// Card avec style fantasy et effets visuels
class FantasyCard extends StatefulWidget {
  final Widget child;
  final Color? glowColor;
  final EdgeInsets? padding;
  final bool animated;

  const FantasyCard({
    super.key,
    required this.child,
    this.glowColor,
    this.padding,
    this.animated = true,
  });

  @override
  State<FantasyCard> createState() => _FantasyCardState();
}

class _FantasyCardState extends State<FantasyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );
      _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF1AA7EC);

    if (widget.animated && _isHovered) {
      _controller.repeat(reverse: true);
    } else if (widget.animated) {
      _controller.stop();
      _controller.reset();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: widget.animated ? _glowAnimation : const AlwaysStoppedAnimation(0.4),
        builder: (context, child) {
          return Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1422),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: glowColor.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(widget.animated ? _glowAnimation.value : 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: glowColor.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

