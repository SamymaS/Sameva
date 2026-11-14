import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Consumer, Provider;
import 'package:provider/provider.dart';
import '../../../core/avatar/apparence_avatar.dart';
import '../../../data/models/character_model.dart';
import '../../../data/models/item_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar/avatar_joueur.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Fiche personnage — stats du joueur en un coup d'œil.
class AvatarPage extends StatelessWidget {
  const AvatarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final player = context.watch<PlayerViewModel>();
    final stats = player.stats;

    final level = stats?.level ?? 1;
    final xp = stats?.experience ?? 0;
    final xpNext = player.experienceForLevel(level);
    final xpProgress = xpNext > 0 ? (xp / xpNext).clamp(0.0, 1.0) : 0.0;
    final hp = stats?.healthPoints ?? 100;
    final maxHp = stats?.maxHealthPoints ?? 100;
    final moral = stats?.moral ?? 1.0;
    final streak = stats?.streak ?? 0;
    final gold = stats?.gold ?? 0;
    final crystals = stats?.crystals ?? 0;
    final totalQuests = stats?.totalQuestsCompleted ?? 0;
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        elevation: 0,
        title: const Text(
          'Personnage',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + niveau
            _Cabine(level: level),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 24),

            // Barre XP
            _StatBar(
              label: 'Expérience',
              value: xp,
              max: xpNext,
              progress: xpProgress,
              color: AppColors.primaryVioletLight,
              suffix: 'XP',
            ),
            const SizedBox(height: 12),

            // Barre HP
            _StatBar(
              label: 'Points de vie',
              value: hp,
              max: maxHp,
              progress: maxHp > 0 ? hp / maxHp : 1.0,
              color: AppColors.mintMagic,
              suffix: 'HP',
            ),
            const SizedBox(height: 12),

            // Barre Morale
            _StatBar(
              label: 'Morale',
              value: (moral * 100).round(),
              max: 100,
              progress: moral,
              color: AppColors.crystalBlue,
              suffix: '%',
            ),
            const SizedBox(height: 24),

            // Grille de stats
            _StatsGrid(streak: streak, gold: gold, crystals: crystals, totalQuests: totalQuests),
            const SizedBox(height: 24),

            // Équipement actuel
            const _EquipmentSection(),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

/// Cabine d'essayage : le personnage en grand, qu'on fait tourner, la planche
/// de ses angles de vue, et les réglages d'apparence illustrés par des vignettes.
class _Cabine extends ConsumerStatefulWidget {
  const _Cabine({required this.level});

  final int level;

  @override
  ConsumerState<_Cabine> createState() => _CabineState();
}

enum _Onglet {
  silhouette('Corps'),
  teint('Teint'),
  coiffure('Coiffure'),
  couleur('Couleur');

  const _Onglet(this.libelle);
  final String libelle;
}

class _CabineState extends ConsumerState<_Cabine> {
  static const _vues = ['Face', 'Trois quarts', 'Profil', 'Trois quarts dos', 'Dos'];
  static const _nomsCouleurs = [
    'noir', 'brun foncé', 'brun', 'blond doré', 'blond clair',
    'rouge', 'violet', 'turquoise', 'gris', 'blanc',
  ];

  int _angle = 0;
  double _glisse = 0;
  _Onglet _onglet = _Onglet.silhouette;

  void _tourner(int pas) => setState(() => _angle = (_angle + pas) % 8);

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(apparenceAvatarProvider);
    final notifier = ref.read(apparenceAvatarProvider.notifier);
    final equipement = context.watch<EquipmentViewModel>();
    final tenue = TenueAvatar.depuisCosmetiques(equipement.getCosmeticSlot);

    Widget fleche(IconData icone, String libelle, int pas) => Semantics(
          container: true,
          button: true,
          label: libelle,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _tourner(pas),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PixelCouleurs.panneau,
                border: Border.all(color: PixelCouleurs.violet, width: 2),
              ),
              child: Icon(icone, color: PixelCouleurs.texte),
            ),
          ),
        );

    Widget vignette({
      required Key key,
      required String libelle,
      required String semantique,
      required bool choisi,
      required CharacterAppearance apercu,
      required VoidCallback onTap,
      bool entier = false,
    }) =>
        _Vignette(
          key: key,
          libelle: libelle,
          semantique: semantique,
          choisi: choisi,
          onTap: onTap,
          child: AvatarJoueur(
            apparence: apercu,
            tenue: tenue,
            hauteur: entier ? 104 : 64,
            cadrage: entier ? CadrageAvatar.entier : CadrageAvatar.buste,
            ombre: false,
            semanticLabel: null,
          ),
        );

    final options = switch (_onglet) {
      _Onglet.silhouette => [
          for (final g in CharacterGender.values)
            vignette(
              key: Key('avatar_silhouette_${g.name}'),
              libelle: g.label,
              semantique: g.label,
              choisi: a.gender == g,
              apercu: a.copyWith(gender: g),
              entier: true,
              onTap: () => notifier.modifier((v) => v.copyWith(gender: g)),
            ),
        ],
      _Onglet.teint => [
          for (final t in SkinTone.values)
            vignette(
              key: Key('avatar_teint_${t.name}'),
              libelle: t.label,
              semantique: 'Teint ${t.label.toLowerCase()}',
              choisi: a.skinTone == t,
              apercu: a.copyWith(skinTone: t),
              onTap: () => notifier.modifier((v) => v.copyWith(skinTone: t)),
            ),
        ],
      _Onglet.coiffure => [
          for (final h in HairStyle.values)
            vignette(
              key: Key('avatar_coiffure_${h.name}'),
              libelle: h.label,
              semantique: h.label,
              choisi: a.hairStyle == h,
              apercu: a.copyWith(hairStyle: h),
              onTap: () => notifier.modifier((v) => v.copyWith(hairStyle: h)),
            ),
        ],
      _Onglet.couleur => [
          for (var i = 0; i < kHairColors.length; i++)
            vignette(
              key: Key('avatar_cheveux_$i'),
              libelle: _nomsCouleurs[i],
              semantique: 'Cheveux ${_nomsCouleurs[i]}',
              choisi: a.hairColor.toARGB32() == kHairColors[i].toARGB32(),
              apercu: a.copyWith(hairColor: kHairColors[i]),
              onTap: () => notifier.modifier((v) => v.copyWith(hairColor: kHairColors[i])),
            ),
        ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Le personnage, sur son podium ──
        PixelCadre(
          bord: PixelCouleurs.violet,
          fond: PixelCouleurs.panneauProfond,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) {
                  _glisse += d.delta.dx;
                  if (_glisse.abs() >= 28) {
                    _tourner(_glisse > 0 ? 1 : 7);
                    _glisse = 0;
                  }
                },
                onHorizontalDragEnd: (_) => _glisse = 0,
                child: SizedBox(
                  height: 300,
                  child: Center(
                    child: AvatarJoueur(apparence: a, tenue: tenue, hauteur: 300, angle: _angle),
                  ),
                ),
              ),
              Positioned(left: 0, bottom: 0, child: fleche(Icons.rotate_left, 'Tourner vers la gauche', 7)),
              Positioned(right: 0, bottom: 0, child: fleche(Icons.rotate_right, 'Tourner vers la droite', 1)),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: PixelCouleurs.or,
                  child: Text('Niv. ${widget.level}', style: PixelTextes.chiffres(9, PixelCouleurs.nuit)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Planche des angles de vue ──
        Row(
          children: [
            for (var i = 0; i < _vues.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: Semantics(
                    container: true,
                    button: true,
                    selected: _angle == i,
                    label: 'Vue ${_vues[i].toLowerCase()}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: Key('avatar_vue_$i'),
                      onTap: () => setState(() => _angle = i),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: PixelCouleurs.panneau,
                          border: Border.all(
                              color: _angle == i ? PixelCouleurs.orClair : PixelCouleurs.trait,
                              width: _angle == i ? 3 : 2),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AvatarJoueur(
                              apparence: a, tenue: tenue, hauteur: 92, angle: i, ombre: false, semanticLabel: null),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Réglages d'apparence ──
        PixelCadre(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apparence', style: PixelTextes.chiffres(11, PixelCouleurs.orClair)),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final o in _Onglet.values)
                  PixelChoix(
                    key: Key('avatar_onglet_${o.name}'),
                    libelle: o.libelle,
                    choisi: _onglet == o,
                    onTap: () => setState(() => _onglet = o),
                  ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: options),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vignette d'une option : l'aperçu du personnage et son nom.
class _Vignette extends StatelessWidget {
  const _Vignette({
    super.key,
    required this.libelle,
    required this.semantique,
    required this.choisi,
    required this.onTap,
    required this.child,
  });

  final String libelle;
  final String semantique;
  final bool choisi;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        selected: choisi,
        label: semantique,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 84,
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
            decoration: BoxDecoration(
              color: choisi ? PixelCouleurs.violetSombre : PixelCouleurs.panneauProfond,
              border: Border.all(color: choisi ? PixelCouleurs.orClair : PixelCouleurs.trait, width: choisi ? 3 : 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(height: 4),
                Text(
                  libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PixelTextes.corps(13, couleur: choisi ? PixelCouleurs.texte : PixelCouleurs.texteDoux),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final double progress;
  final Color color;
  final String suffix;

  const _StatBar({
    required this.label,
    required this.value,
    required this.max,
    required this.progress,
    required this.color,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              Text('$value / $max $suffix',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.backgroundNightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int streak;
  final int gold;
  final int crystals;
  final int totalQuests;

  const _StatsGrid({
    required this.streak,
    required this.gold,
    required this.crystals,
    required this.totalQuests,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _StatTile(
          icon: Icons.local_fire_department,
          color: AppColors.coralRare,
          label: 'Série',
          value: '$streak j',
        ),
        _StatTile(
          icon: Icons.monetization_on_outlined,
          color: AppColors.gold,
          label: 'Or',
          value: '$gold',
        ),
        _StatTile(
          icon: Icons.diamond_outlined,
          color: AppColors.crystalBlue,
          label: 'Cristaux',
          value: '$crystals',
        ),
        _StatTile(
          icon: Icons.check_circle_outline,
          color: AppColors.mintMagic,
          label: 'Quêtes',
          value: '$totalQuests',
        ),
      ],
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection();

  static const _slots = [
    (slot: EquipmentSlot.weapon,  label: 'Arme',    icon: Icons.sports_martial_arts_outlined),
    (slot: EquipmentSlot.armor,   label: 'Armure',  icon: Icons.shield_outlined),
    (slot: EquipmentSlot.helmet,  label: 'Casque',  icon: Icons.face_outlined),
    (slot: EquipmentSlot.boots,   label: 'Bottes',  icon: Icons.directions_run_outlined),
    (slot: EquipmentSlot.ring,    label: 'Anneau',  icon: Icons.circle_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentViewModel>(
      builder: (_, equipment, __) {
        final totalHp = equipment.hpBonus;
        final totalXp = equipment.xpBonusPercent;
        final totalGold = equipment.goldBonusPercent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Équipement',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            // Slots
            ...(_slots.map((s) {
              final item = equipment.getSlot(s.slot);
              final color = item != null
                  ? AppColors.getRarityColor(item.rarity.name)
                  : AppColors.textMuted.withValues(alpha: 0.3);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDarkPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(s.icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.label,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10),
                          ),
                          Text(
                            item?.name ?? 'Vide',
                            style: TextStyle(
                              color: item != null
                                  ? color
                                  : AppColors.textMuted.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item != null)
                      Wrap(
                        spacing: 4,
                        children: item.stats.entries
                            .where((e) => e.value != 0)
                            .map((e) {
                          final label = switch (e.key) {
                            'hpBonus'    => 'HP+${e.value}',
                            'xpBonus'    => 'XP+${e.value}%',
                            'goldBonus'  => 'Or+${e.value}%',
                            'moralBonus' => 'Moral+${e.value}',
                            _            => '${e.key}+${e.value}',
                          };
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: color, fontSize: 9)),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            })),
            // Résumé des bonus totaux
            if (totalHp > 0 || totalXp > 0 || totalGold > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTurquoise.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryTurquoise.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (totalHp > 0)
                      _BonusChip(label: 'HP max', value: '+$totalHp'),
                    if (totalXp > 0)
                      _BonusChip(label: 'XP', value: '+$totalXp%'),
                    if (totalGold > 0)
                      _BonusChip(label: 'Or', value: '+$totalGold%'),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BonusChip extends StatelessWidget {
  final String label;
  final String value;
  const _BonusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.primaryTurquoise,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
