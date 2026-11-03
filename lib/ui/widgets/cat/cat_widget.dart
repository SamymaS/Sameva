import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../pixel/pixel_sprite.dart';

/// Couleur représentative du pelage (halos, lueurs autour du chat).
/// Elle reprend le ton « reflet » des sprites pixel art (tools/pixel).
Color catBodyColor(String race) => switch (race) {
      'michi'  => const Color(0xFF8E7FB8), // tuxedo : reflet violacé
      'lune'   => const Color(0xFFE4E0F2), // blanc nacré
      'braise' => const Color(0xFFFCB46A), // roux
      'neige'  => const Color(0xFFC6DEF0), // gris-bleu
      'cosmos' => const Color(0xFF8862CE), // violet nuit étoilé
      'sakura' => const Color(0xFFF8C8D4), // rose
      _        => AppColors.primaryVioletLight,
    };

const _races = {'michi', 'lune', 'braise', 'neige', 'cosmos', 'sakura'};

/// Animation du chat selon l'humeur (accepte aussi les noms de CatMoodService).
String animationPourHumeur(String mood) => switch (mood.replaceFirst('cat_', '')) {
      'happy' => 'content',
      'excited' => 'excite',
      'sad' => 'triste',
      'sleepy' => 'endormi',
      _ => 'repos',
    };

/// Chat compagnon en pixel art (Sprint 2, direction Stardew Valley / Celeste).
///
/// Superpose : halo d'aura, chat animé selon l'humeur (sprites 64 px issus du
/// fichier Figma « Sameva · Pixel art ») et chapeau. Les tenues (haut,
/// pantalon, chaussures, accessoire) ne sont plus dessinées sur le chat :
/// elles restent visibles dans l'inventaire en attendant des sprites habillés.
class CatWidget extends StatefulWidget {
  final String race;
  final String? equippedHat;
  final Color? outfitColor;
  final Color? pantsColor;
  final Color? shoesColor;
  final Color? accessoryColor;
  final Color? auraColor;
  final double size;
  final String mood;

  const CatWidget({
    super.key,
    required this.race,
    this.equippedHat,
    this.outfitColor,
    this.pantsColor,
    this.shoesColor,
    this.accessoryColor,
    this.auraColor,
    this.size = 160,
    this.mood = 'happy',
  });

  @override
  State<CatWidget> createState() => _CatWidgetState();
}

class _CatWidgetState extends State<CatWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _auraCtrl;

  @override
  void initState() {
    super.initState();
    _auraCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    if (widget.auraColor != null) _auraCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CatWidget old) {
    super.didUpdateWidget(old);
    if (widget.auraColor != null && !_auraCtrl.isAnimating) _auraCtrl.repeat(reverse: true);
    if (widget.auraColor == null && _auraCtrl.isAnimating) _auraCtrl.stop();
  }

  @override
  void dispose() {
    _auraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final race = _races.contains(widget.race) ? widget.race : 'michi';
    final s = widget.size;
    return Semantics(
      image: true,
      label: 'Chat compagnon',
      child: SizedBox.square(
        dimension: s,
        child: AvecManifeste(
          cote: s,
          builder: (context, m) {
            final chapeau = widget.equippedHat == null ? null : m.chapeau(widget.equippedHat!);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (widget.auraColor != null)
                  AnimatedBuilder(
                    animation: _auraCtrl,
                    builder: (_, __) => _AuraLayer(
                      color: widget.auraColor!,
                      pulse: 0.4 + 0.5 * _auraCtrl.value,
                      size: s,
                    ),
                  ),
                PixelSprite(
                  feuille: 'assets/sprites/chat_$race.png',
                  animation: m.animation('chat', animationPourHumeur(widget.mood)),
                  taille: m.taille('chat'),
                  cote: s,
                ),
                // Chapeau : icône d'objet posée sur la tête.
                if (chapeau != null)
                  Positioned(
                    top: s * 0.02,
                    child: Image.asset(
                      'assets/sprites/objets/$chapeau.png',
                      width: s * 0.36,
                      height: s * 0.36,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Halo lumineux pulsant derrière le chat.
class _AuraLayer extends StatelessWidget {
  final Color color;
  final double pulse;
  final double size;

  const _AuraLayer({required this.color, required this.pulse, required this.size});

  @override
  Widget build(BuildContext context) {
    final ringSize = size * 1.1;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: pulse * 0.7), width: size * 0.03),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: pulse * 0.5), blurRadius: size * 0.25, spreadRadius: size * 0.04),
            BoxShadow(color: color.withValues(alpha: pulse * 0.3), blurRadius: size * 0.45, spreadRadius: size * 0.02),
          ],
        ),
      ),
    );
  }
}
