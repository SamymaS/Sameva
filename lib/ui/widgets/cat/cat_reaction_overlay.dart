import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../theme/app_colors.dart';
import 'cat_widget.dart';

/// Overlay affiché après une validation de quête réussie.
/// Montre le chat animé + message personnalisé, puis se ferme après 2 secondes.
///
/// Usage :
/// ```dart
/// await showCatReactionOverlay(
///   context,
///   race: 'cosmos',
///   mood: CatMood.excited,
///   questResult: 'success',
/// );
/// ```
Future<void> showCatReactionOverlay(
  BuildContext context, {
  required String race,
  String? equippedHat,
  required CatMood mood,
  required String questResult,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.60),
    builder: (_) => _CatReactionOverlay(
      race: race,
      equippedHat: equippedHat,
      mood: mood,
      questResult: questResult,
    ),
  );
}

class _CatReactionOverlay extends StatefulWidget {
  final String race;
  final String? equippedHat;
  final CatMood mood;
  final String questResult;

  const _CatReactionOverlay({
    required this.race,
    required this.equippedHat,
    required this.mood,
    required this.questResult,
  });

  @override
  State<_CatReactionOverlay> createState() => _CatReactionOverlayState();
}

class _CatReactionOverlayState extends State<_CatReactionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    // Auto-dismiss après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = CatMoodService.getCatReactionMessage(
        widget.mood, widget.questResult);
    final bodyColor = catBodyColor(widget.race);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => FadeTransition(
          opacity: _fade,
          child: Transform.scale(
            scale: _scale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glow + chat
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: bodyColor.withValues(alpha: 0.45),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    CatWidget(
                      race: widget.race,
                      equippedHat: widget.equippedHat,
                      size: 180,
                      mood: CatMoodService.getIdleAnimation(widget.mood),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Carte message
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color:
                            AppColors.backgroundDarkPanel.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              bodyColor.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Icône succès
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.mintMagic.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.mintMagic,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Message du chat
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Humeur
                          Text(
                            '${CatMoodService.moodEmoji(widget.mood)}  ${CatMoodService.moodLabel(widget.mood)}',
                            style: GoogleFonts.nunito(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
