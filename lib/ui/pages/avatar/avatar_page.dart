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
            _AvatarHeader(level: level, email: email),
            const SizedBox(height: 16),
            const _SectionApparence(),
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

class _AvatarHeader extends StatelessWidget {
  final int level;
  final String email;

  const _AvatarHeader({required this.level, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PixelCadre(
          bord: PixelCouleurs.violet,
          fond: PixelCouleurs.panneauProfond,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              const AvatarJoueurConnecte(hauteur: 190),
              Positioned(
                right: -40,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: PixelCouleurs.or,
                  child: Text('Niv. $level', style: PixelTextes.chiffres(9, PixelCouleurs.nuit)),
                ),
              ),
            ],
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ],
    );
  }
}

/// Personnalisation de l'avatar : silhouette, teint, coiffure, couleur des cheveux.
class _SectionApparence extends ConsumerWidget {
  const _SectionApparence();

  static const _nomsCouleurs = [
    'noir', 'brun foncé', 'brun', 'blond doré', 'blond clair',
    'rouge', 'violet', 'turquoise', 'gris', 'blanc',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(apparenceAvatarProvider);
    final notifier = ref.read(apparenceAvatarProvider.notifier);

    Widget titre(String t) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(t, style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux, poids: FontWeight.w700)),
        );

    return PixelCadre(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apparence', style: PixelTextes.chiffres(11, PixelCouleurs.orClair)),
          titre('Silhouette'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final g in CharacterGender.values)
              PixelChoix(
                key: Key('avatar_silhouette_${g.name}'),
                libelle: g.label,
                choisi: a.gender == g,
                onTap: () => notifier.modifier((v) => v.copyWith(gender: g)),
              ),
          ]),
          titre('Teint'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in SkinTone.values)
              _Pastille(
                key: Key('avatar_teint_${t.name}'),
                couleur: t.color,
                libelle: 'Teint ${t.label.toLowerCase()}',
                choisi: a.skinTone == t,
                onTap: () => notifier.modifier((v) => v.copyWith(skinTone: t)),
              ),
          ]),
          titre('Coiffure'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in HairStyle.values)
              PixelChoix(
                key: Key('avatar_coiffure_${h.name}'),
                libelle: h.label,
                choisi: a.hairStyle == h,
                onTap: () => notifier.modifier((v) => v.copyWith(hairStyle: h)),
              ),
          ]),
          titre('Couleur des cheveux'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < kHairColors.length; i++)
              _Pastille(
                key: Key('avatar_cheveux_$i'),
                couleur: kHairColors[i],
                libelle: 'Cheveux ${_nomsCouleurs[i]}',
                choisi: a.hairColor.toARGB32() == kHairColors[i].toARGB32(),
                onTap: () => notifier.modifier((v) => v.copyWith(hairColor: kHairColors[i])),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Pastille de couleur carrée (48 px : cible tactile confortable).
class _Pastille extends StatelessWidget {
  const _Pastille({super.key, required this.couleur, required this.libelle, required this.choisi, required this.onTap});

  final Color couleur;
  final String libelle;
  final bool choisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        selected: choisi,
        label: libelle,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: choisi ? PixelCouleurs.orClair : PixelCouleurs.trait, width: choisi ? 4 : 2),
            ),
            child: ColoredBox(color: couleur),
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
