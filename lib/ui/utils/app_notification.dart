import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Affiche une notification animée en haut de l'écran (remplace les SnackBar bas).
/// File d'attente : max 3 simultanées, dédup du dernier message identique
/// dans une fenêtre de 1.5s (évite spam sur multi-pull).
class AppNotification {
  AppNotification._();

  static const int _maxConcurrent = 3;
  static const Duration _dedupWindow = Duration(milliseconds: 1500);
  static final List<OverlayEntry> _active = [];
  static String? _lastMessage;
  static DateTime? _lastShownAt;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Color backgroundColor = AppColors.backgroundDarkPanel,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dédup : même message dans la fenêtre récente → ignore
    final now = DateTime.now();
    if (_lastMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupWindow) {
      return;
    }
    _lastMessage = message;
    _lastShownAt = now;

    // Cap concurrent : retire la plus ancienne si plein
    if (_active.length >= _maxConcurrent) {
      final oldest = _active.removeAt(0);
      try {
        oldest.remove();
      } catch (_) {}
    }

    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    late OverlayEntry entry;
    final stackIndex = _active.length;
    entry = OverlayEntry(
      builder: (_) => _TopNotificationWidget(
        message: message,
        icon: icon,
        iconColor: iconColor,
        backgroundColor: backgroundColor,
        topPadding: topPadding + stackIndex * 64.0,
        onDismiss: () {
          _active.remove(entry);
          try {
            entry.remove();
          } catch (_) {}
        },
        duration: duration,
      ),
    );

    _active.add(entry);
    overlay.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final Color backgroundColor;
  final double topPadding;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopNotificationWidget({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.topPadding,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.iconColor ?? AppColors.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
