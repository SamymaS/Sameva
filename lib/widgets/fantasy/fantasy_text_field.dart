import 'package:flutter/material.dart';

/// TextField avec style fantasy
class FantasyTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? glowColor;

  const FantasyTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.glowColor,
  });

  @override
  State<FantasyTextField> createState() => _FantasyTextFieldState();
}

class _FantasyTextFieldState extends State<FantasyTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.glowColor ?? const Color(0xFF1AA7EC);

    if (_isFocused) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? glowColor.withOpacity(_glowAnimation.value)
                  : glowColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(_glowAnimation.value * 0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              labelStyle: TextStyle(
                color: _isFocused ? glowColor : Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: const Color(0xFF0E1422).withOpacity(0.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onTap: () => setState(() => _isFocused = true),
            onChanged: (value) {
              if (value.isEmpty && _isFocused) {
                setState(() => _isFocused = false);
              }
            },
          ),
        );
      },
    );
  }
}

