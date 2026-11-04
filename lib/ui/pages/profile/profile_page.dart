import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/feature_flags.dart';
import '../../../data/models/item_model.dart';
import '../../../domain/services/activity_log_service.dart';
import 'achievements_page.dart';
import '../auth/save_guest_account_page.dart';
import '../social/leaderboard_page.dart';
import '../inventory/inventory_page.dart';
import 'activity_log_page.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/profile_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_widget.dart';
import '../../widgets/common/item_icon.dart';
import '../../widgets/pixel/pixel_ui.dart';
import 'delete_account_confirm_dialog.dart';

/// Couleurs d'état propres au profil (lisibles sur fond nuit).
abstract final class _Teintes {
  static const vert = Color(0xFF4ADE80);
  static const rouge = Color(0xFFFCA5A5);
  static const rougeVif = Color(0xFFEF4444);
}

/// Page Profil (style pixel) : tête de profil, soldes, sections en cadres épais.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthViewModel>().userId;
    if (userId != null && _vm == null) {
      _vm = ProfileViewModel(
        context.read<AuthViewModel>(),
        context.read<PlayerRepository>(),
        context.read<QuestViewModel>(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _vm != null) _vm!.load(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const chargement = Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      body: Center(child: CircularProgressIndicator(color: PixelCouleurs.violetClair)),
    );
    if (_vm == null) return chargement;

    return ChangeNotifierProvider<ProfileViewModel>.value(
      value: _vm!,
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) => vm.isLoading ? chargement : _ProfileContent(vm: vm),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final ProfileViewModel vm;

  const _ProfileContent({required this.vm});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryViewModel>();
    final equipment = context.watch<EquipmentViewModel>();
    final stats = vm.stats;

    final level = stats?.level ?? 1;
    final experience = stats?.experience ?? 0;
    final xpForNext = vm.experienceForLevel(level);
    final xpProgress = xpForNext > 0 ? (experience / xpForNext).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: pixelBarre(
        'Profil',
        actions: [
          if (FeatureFlags.showLeaderboard)
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined, color: PixelCouleurs.violetClair),
              tooltip: 'Classement',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardPage()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: PixelCouleurs.or),
            tooltip: 'Succès',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined, color: PixelCouleurs.texteDoux),
            tooltip: 'Partager',
            onPressed: () => _shareProfile(context, vm, stats),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: PixelCouleurs.texteDoux),
            tooltip: 'Réglages',
            onPressed: () => context.push(Routes.parametres),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HeroHeader(
            vm: vm,
            level: level,
            experience: experience,
            xpForNext: xpForNext,
            xpProgress: xpProgress,
            stats: stats,
          ),
          const SizedBox(height: 14),
          _QuickStatsRow(stats: stats, vm: vm),
          const SizedBox(height: 16),

          // Bandeau invité : visible uniquement pour les comptes anonymes
          if (context.watch<AuthViewModel>().isGuest) ...[
            const _GuestBanner(),
            const SizedBox(height: 16),
          ],

          // Premium (appel à l'abonnement ou statut actif)
          const _PremiumSection(),
          const SizedBox(height: 16),

          _EquipmentSummary(equipment: equipment),
          const SizedBox(height: 16),

          _InventorySummary(inventory: inventory),
          const SizedBox(height: 16),

          const _CatSection(),
          const SizedBox(height: 16),

          _StatisticsSection(vm: vm),
          const SizedBox(height: 16),

          _AchievementsSection(stats: stats),
          const SizedBox(height: 16),

          const _ActivityChart(),
          const SizedBox(height: 16),

          if (FeatureFlags.showHistory) ...[
            PixelBouton(
              libelle: 'Historique d\'activité',
              principal: false,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ActivityLogPage()),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _LogoutButton(vm: vm),
          const SizedBox(height: 28),

          // Zone sensible : suppression de compte (RGPD)
          const _DangerZoneDivider(),
          const SizedBox(height: 16),
          _DeleteAccountButton(vm: vm),
        ],
      ),
    );
  }

  void _shareProfile(BuildContext context, ProfileViewModel vm, PlayerStats? stats) {
    final level = stats?.level ?? 1;
    final gold = stats?.gold ?? 0;
    final crystals = stats?.crystals ?? 0;
    final streak = stats?.streak ?? 0;
    final quests = vm.completedCount;
    final title = _HeroHeader._playerTitle(stats);

    final lines = [
      '⚔️ Mon profil Sameva',
      if (title != null) '🏆 $title',
      '─────────────────',
      '📈 Niveau $level',
      '✅ $quests quêtes complétées',
      '🔥 Série : $streak jours',
      '💰 Or : $gold  |  💎 Cristaux : $crystals',
      '─────────────────',
      'Rejoins-moi sur Sameva, l\'app RPG de productivité !',
    ];

    Share.share(lines.join('\n'));
  }
}

// ─── Tête de profil ──────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ProfileViewModel vm;
  final int level;
  final int experience;
  final int xpForNext;
  final double xpProgress;
  final PlayerStats? stats;

  const _HeroHeader({
    required this.vm,
    required this.level,
    required this.experience,
    required this.xpForNext,
    required this.xpProgress,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final titre = _playerTitle(stats);
    final serie = stats?.streak ?? 0;
    return PixelCadre(
      bord: PixelCouleurs.violet,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar : toucher pour ouvrir la fiche personnage
          Semantics(
            container: true,
            button: true,
            label: 'Fiche personnage',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => context.push(Routes.avatar),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: PixelCouleurs.violetSombre,
                  border: Border(
                    top: BorderSide(color: PixelCouleurs.violetClair, width: 3),
                    left: BorderSide(color: PixelCouleurs.violetClair, width: 3),
                    right: BorderSide(color: PixelCouleurs.violetClair, width: 3),
                    bottom: BorderSide(color: PixelCouleurs.violet, width: 6),
                  ),
                ),
                child: const Icon(Icons.person, color: PixelCouleurs.texte, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vm.userEmail != null)
                  Text(vm.userEmail!,
                      overflow: TextOverflow.ellipsis, style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
                if (titre != null)
                  Text(titre, style: PixelTextes.corps(15, couleur: PixelCouleurs.orClair, poids: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: PixelCouleurs.oracle,
                      child: Text('Niv. $level', style: PixelTextes.chiffres(9, PixelCouleurs.nuit)),
                    ),
                    if (serie >= 7)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: PixelCouleurs.or, width: 2)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: PixelCouleurs.or, size: 14),
                            const SizedBox(width: 3),
                            Text('$serie j',
                                style: PixelTextes.corps(14, couleur: PixelCouleurs.orClair, poids: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Semantics(
                  container: true,
                  label: 'Expérience $experience sur $xpForNext',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      Expanded(child: PixelJauge(valeur: xpProgress, couleur: PixelCouleurs.oracle, hauteur: 12)),
                      const SizedBox(width: 8),
                      Text('$experience / $xpForNext', style: PixelTextes.chiffres(8, PixelCouleurs.texteDoux)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne le titre le plus prestigieux débloqué par le joueur.
  static String? _playerTitle(PlayerStats? stats) {
    if (stats == null || stats.achievements.isEmpty) return null;
    const priority = [
      'quest_100',
      'level_25',
      'streak_30',
      'rich_5000',
      'quest_50',
      'level_10',
      'streak_7',
      'rich_1000',
      'quest_10',
      'level_5',
      'collector_25',
      'zen_master',
      'collector_10',
      'streak_3',
      'first_quest',
    ];
    for (final id in priority) {
      if (stats.achievements.containsKey(id)) {
        final def = PlayerStats.achievementDefinitions.firstWhere((d) => d['id'] == id, orElse: () => {});
        if (def['name'] != null) return def['name'];
      }
    }
    return null;
  }
}

// ─── Soldes ──────────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final PlayerStats? stats;
  final ProfileViewModel vm;

  const _QuickStatsRow({required this.stats, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(icon: Icons.monetization_on, color: PixelCouleurs.or, label: '${stats?.gold ?? 0}', sublabel: 'Or'),
        const SizedBox(width: 8),
        _StatChip(
            icon: Icons.diamond,
            color: PixelCouleurs.violetClair,
            label: '${stats?.crystals ?? 0}',
            sublabel: 'Cristaux'),
        const SizedBox(width: 8),
        _StatChip(icon: Icons.favorite, color: _Teintes.rouge, label: '${stats?.healthPoints ?? 100}', sublabel: 'PV'),
        const SizedBox(width: 8),
        _StatChip(icon: Icons.check, color: _Teintes.vert, label: '${vm.completedCount}', sublabel: 'Quêtes'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;

  const _StatChip({required this.icon, required this.color, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MergeSemantics(
        child: PixelCadre(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: PixelTextes.chiffres(11, color)),
              ),
              const SizedBox(height: 2),
              Text(sublabel, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bandeau invité ──────────────────────────────────────────────────────────

/// Bandeau affiché uniquement pour les comptes anonymes (isGuest == true).
/// Invite l'utilisateur à sauvegarder sa progression en créant un compte e-mail.
class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      bord: PixelCouleurs.or,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: PixelCouleurs.or, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text('Mode invité', style: PixelTextes.chiffres(11, PixelCouleurs.orClair))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ta progression n\'est liée qu\'à cet appareil. Sauvegarde ton compte pour ne rien perdre si tu '
            'changes de téléphone.',
            style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux),
          ),
          const SizedBox(height: 14),
          PixelBouton(
            key: const Key('btn_sauvegarder_progression'),
            libelle: 'Sauvegarder ma progression',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SaveGuestAccountPage()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium ─────────────────────────────────────────────────────────────────

/// Section Premium de la page Profil.
///
/// Point d'entrée permanent vers l'abonnement (le panneau « plus de jetons » ne
/// s'affiche qu'au blocage à 0 jeton). Affiche :
/// - si premium actif : statut et date d'expiration ;
/// - sinon : « Passer à Premium », qui lance le paiement Stripe via
///   [AiValidationCreditsService.startPremiumCheckout].
class _PremiumSection extends StatelessWidget {
  const _PremiumSection();

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<AiValidationCreditsService>();

    if (credits.isPremium) {
      return _PremiumActiveCard(until: credits.premiumUntil);
    }
    return _PremiumCtaCard(
      onSubscribe: () => context.read<AiValidationCreditsService>().startPremiumCheckout(),
    );
  }
}

/// Carte affichée quand l'abonnement Premium est actif.
class _PremiumActiveCard extends StatelessWidget {
  final DateTime? until;

  const _PremiumActiveCard({required this.until});

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      bord: PixelCouleurs.or,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: PixelCouleurs.or, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium actif', style: PixelTextes.chiffres(11, PixelCouleurs.orClair)),
                const SizedBox(height: 4),
                Text(
                  until != null
                      ? 'Validations IA illimitées · renouvellement le ${_formatDate(until!)}'
                      : 'Validations IA illimitées',
                  style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    final jj = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$jj/$mm/${local.year}';
  }
}

/// Carte d'appel à l'abonnement Premium (non abonné).
class _PremiumCtaCard extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PremiumCtaCard({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      bord: PixelCouleurs.violet,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: PixelCouleurs.violetClair, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text('Sameva Premium', style: PixelTextes.chiffres(11, PixelCouleurs.texte))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Validations MougiBot illimitées : l\'analyse IA de toutes tes preuves de quête, sans compter '
            'l\'énergie.',
            style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux),
          ),
          const SizedBox(height: 14),
          PixelBouton(
            key: const Key('cta_premium_profil'),
            libelle: 'Passer à Premium',
            onPressed: onSubscribe,
          ),
        ],
      ),
    );
  }
}

// ─── Équipement ──────────────────────────────────────────────────────────────

class _EquipmentSummary extends StatelessWidget {
  final EquipmentViewModel equipment;

  const _EquipmentSummary({required this.equipment});

  @override
  Widget build(BuildContext context) {
    final equipped = equipment.equipped.values.where((i) => i != null).toList();
    final xp = equipment.xpBonusPercent;
    final gold = equipment.goldBonusPercent;
    final hp = equipment.hpBonus;

    return _SectionCard(
      title: 'Équipement',
      icon: Icons.shield_outlined,
      child: equipped.isEmpty
          ? const _TexteVide('Aucun équipement actif.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: equipped.map((item) {
                    final color = AppColors.getRarityColor(item!.rarity.name);
                    return Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                      decoration: BoxDecoration(
                        color: PixelCouleurs.panneauProfond,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ItemIcon(item: item, size: 28, showBackground: false),
                          const SizedBox(width: 6),
                          Text(item.name, style: PixelTextes.corps(14, couleur: color, poids: FontWeight.w700)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (xp > 0 || gold > 0 || hp > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (xp > 0) _BonusBadge('+$xp % XP', PixelCouleurs.oracle),
                      if (gold > 0) _BonusBadge('+$gold % or', PixelCouleurs.or),
                      if (hp > 0) _BonusBadge('+$hp PV', _Teintes.rouge),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _BonusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _BonusBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: PixelCouleurs.panneauProfond,
      child: Text(text, style: PixelTextes.corps(14, couleur: color, poids: FontWeight.w700)),
    );
  }
}

// ─── Inventaire ──────────────────────────────────────────────────────────────

class _InventorySummary extends StatelessWidget {
  final InventoryViewModel inventory;

  const _InventorySummary({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final items = inventory.items;
    final weapons = items.where((i) => i.type == ItemType.weapon).length;
    final armors = items
        .where((i) =>
            i.type == ItemType.armor ||
            i.type == ItemType.helmet ||
            i.type == ItemType.boots ||
            i.type == ItemType.ring)
        .length;
    final potions = items.where((i) => i.type == ItemType.potion).length;

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InventoryPage()),
          ),
          behavior: HitTestBehavior.opaque,
          child: _SectionCard(
            title: 'Inventaire',
            icon: Icons.inventory_2_outlined,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${items.length} / 50', style: PixelTextes.chiffres(8, PixelCouleurs.texteDoux)),
                const Icon(Icons.chevron_right, color: PixelCouleurs.texteDoux, size: 20),
              ],
            ),
            child: items.isEmpty
                ? const _TexteVide('Inventaire vide.')
                : Row(
                    children: [
                      _InvTypeChip(Icons.auto_fix_high, '$weapons', 'Armes', AppColors.rarityLegendary),
                      const SizedBox(width: 8),
                      _InvTypeChip(Icons.shield_outlined, '$armors', 'Armures', AppColors.rarityRare),
                      const SizedBox(width: 8),
                      _InvTypeChip(Icons.local_pharmacy, '$potions', 'Potions', _Teintes.vert),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _InvTypeChip extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _InvTypeChip(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: PixelCouleurs.panneauProfond,
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(count, style: PixelTextes.chiffres(11, color)),
            Text(label, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
          ],
        ),
      ),
    );
  }
}

// ─── Succès ──────────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final PlayerStats? stats;

  const _AchievementsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final unlocked = stats?.achievements ?? {};
    const definitions = PlayerStats.achievementDefinitions;
    final unlockedCount = unlocked.length;

    return _SectionCard(
      title: 'Succès',
      icon: Icons.emoji_events_outlined,
      trailing: Text('$unlockedCount / ${definitions.length}', style: PixelTextes.chiffres(8, PixelCouleurs.texteDoux)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: definitions.length,
        itemBuilder: (context, i) {
          final def = definitions[i];
          final isUnlocked = unlocked.containsKey(def['id']);
          return Semantics(
            container: true,
            button: true,
            label: '${def['name'] ?? ''}, ${isUnlocked ? 'débloqué' : 'verrouillé'}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _showAchievementTooltip(context, def, isUnlocked),
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isUnlocked ? PixelCouleurs.violetSombre : PixelCouleurs.panneauProfond,
                  border:
                      Border.all(color: isUnlocked ? PixelCouleurs.or : PixelCouleurs.trait, width: isUnlocked ? 3 : 2),
                ),
                child: Icon(
                  _iconForName(def['icon'] ?? 'star'),
                  color: isUnlocked ? PixelCouleurs.or : PixelCouleurs.trait,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAchievementTooltip(BuildContext context, Map<String, String> def, bool isUnlocked) {
    AppNotification.show(
      context,
      message: '${def['name'] ?? ''}${!isUnlocked ? ' (verrouillé)' : ''}\n${def['description'] ?? ''}',
      icon: _iconForName(def['icon'] ?? 'star'),
      iconColor: isUnlocked ? AppColors.gold : AppColors.textMuted,
      duration: const Duration(seconds: 2),
      backgroundColor: isUnlocked ? AppColors.gold.withValues(alpha: 0.2) : AppColors.backgroundDarkPanel,
    );
  }

  IconData _iconForName(String name) {
    return switch (name) {
      'star' => Icons.star,
      'military_tech' => Icons.military_tech,
      'emoji_events' => Icons.emoji_events,
      'workspace_premium' => Icons.workspace_premium,
      'local_fire_department' => Icons.local_fire_department,
      'whatshot' => Icons.whatshot,
      'bolt' => Icons.bolt,
      'trending_up' => Icons.trending_up,
      'school' => Icons.school,
      'psychology' => Icons.psychology,
      'paid' => Icons.paid,
      'diamond' => Icons.diamond,
      'inventory_2' => Icons.inventory_2,
      'warehouse' => Icons.warehouse,
      'self_improvement' => Icons.self_improvement,
      _ => Icons.star_outline,
    };
  }
}

// ─── Chat compagnon ──────────────────────────────────────────────────────────

class _CatSection extends StatelessWidget {
  const _CatSection();

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatViewModel>().mainCat;
    if (cat == null) return const SizedBox.shrink();

    final slots = [
      (label: 'Chapeau', id: cat.equippedHat, icon: Icons.dry_outlined),
      (label: 'Tenue', id: cat.equippedOutfit, icon: Icons.checkroom_outlined),
      (label: 'Aura', id: cat.equippedAura, icon: Icons.auto_awesome_outlined),
      (label: 'Accessoire', id: cat.equippedAccessory, icon: Icons.diamond_outlined),
    ];
    final wornCount = slots.where((s) => s.id != null).length;
    final rarete = AppColors.getRarityColor(cat.rarity);

    return _SectionCard(
      title: 'Mon chat',
      icon: Icons.pets,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: rarete, width: 2)),
        child: Text(_rareteLabel(cat.rarity), style: PixelTextes.corps(13, couleur: rarete, poids: FontWeight.w700)),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.bottomCenter,
            color: PixelCouleurs.panneauProfond,
            child: CatWidget(race: cat.race, equippedHat: cat.equippedHat, size: 72, mood: 'happy'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name.isNotEmpty ? cat.name : cat.race, style: PixelTextes.chiffres(11, PixelCouleurs.texte)),
                const SizedBox(height: 4),
                Text(_raceLabel(cat.race), style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
                const SizedBox(height: 6),
                Semantics(
                  container: true,
                  label: '$wornCount cosmétiques équipés sur 4',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      for (final s in slots)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(s.icon,
                              size: 20, color: s.id != null ? PixelCouleurs.violetClair : PixelCouleurs.trait),
                        ),
                      const SizedBox(width: 4),
                      Text('$wornCount / 4', style: PixelTextes.chiffres(8, PixelCouleurs.texteDoux)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rareteLabel(String r) => switch (r.toLowerCase()) {
        'common' => 'Commun',
        'uncommon' => 'Peu commun',
        'rare' => 'Rare',
        'epic' => 'Épique',
        'legendary' => 'Légendaire',
        'mythic' => 'Mythique',
        _ => r,
      };

  String _raceLabel(String race) => switch (race) {
        'michi' => 'Michi · Sage et calme',
        'lune' => 'Lune · Mystérieux',
        'braise' => 'Braise · Énergique',
        'neige' => 'Neige · Doux et timide',
        'cosmos' => 'Cosmos · Mystique',
        'sakura' => 'Sakura · Joyeux',
        _ => race,
      };
}

// ─── Graphe XP ───────────────────────────────────────────────────────────────

class _ActivityChart extends StatelessWidget {
  const _ActivityChart();

  @override
  Widget build(BuildContext context) {
    final entries = ActivityLogService.getLog();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // XP par jour sur les 14 derniers jours
    final days = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
    final xpByDay = <DateTime, int>{for (final day in days) day: 0};
    for (final entry in entries) {
      if (entry.type == ActivityType.quest && entry.subtitle != null) {
        final match = RegExp(r'\+(\d+) XP').firstMatch(entry.subtitle!);
        if (match != null) {
          final xp = int.tryParse(match.group(1)!) ?? 0;
          final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
          if (xpByDay.containsKey(day)) {
            xpByDay[day] = xpByDay[day]! + xp;
          }
        }
      }
    }

    final values = days.map((d) => xpByDay[d]!.toDouble()).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final total = values.reduce((a, b) => a + b).toInt();

    return _SectionCard(
      title: 'XP sur 14 jours',
      icon: Icons.bar_chart,
      trailing: Text('$total XP', style: PixelTextes.chiffres(8, PixelCouleurs.oracle)),
      child: Semantics(
        container: true,
        label: '$total XP gagnés sur les 14 derniers jours',
        excludeSemantics: true,
        child: Column(
          children: [
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _XpBarChartPainter(values: values, maxVal: maxVal <= 0 ? 1 : maxVal),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_shortDate(days.first), style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
                Text('Aujourd\'hui', style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}';
}

/// Histogramme pixel : barres pleines, sans arrondi, hauteur arrondie à 4 px.
class _XpBarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;

  const _XpBarChartPainter({required this.values, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width - (values.length - 1) * 4) / values.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final socle = Paint()..color = PixelCouleurs.trait;
    canvas.drawRect(Rect.fromLTWH(0, size.height - 2, size.width, 2), socle);

    for (int i = 0; i < values.length; i++) {
      final fraction = values[i] / maxVal;
      if (fraction <= 0) continue;
      // hauteur par paliers de 4 px : rendu « en blocs »
      final barHeight = ((fraction * (size.height - 2)) / 4).ceil() * 4.0;
      final x = i * (barWidth + 4);
      final y = size.height - 2 - barHeight;
      final isToday = i == values.length - 1;
      paint.color = isToday ? PixelCouleurs.or : PixelCouleurs.oracle;
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
      // reflet clair sur le haut de la barre
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, 2), Paint()..color = Colors.white.withValues(alpha: .45));
    }
  }

  @override
  bool shouldRepaint(_XpBarChartPainter old) => old.values != values || old.maxVal != maxVal;
}

// ─── Séparateur zone sensible ────────────────────────────────────────────────

class _DangerZoneDivider extends StatelessWidget {
  const _DangerZoneDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SizedBox(height: 3, child: ColoredBox(color: Color(0xFF7F1D1D)))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Zone sensible', style: PixelTextes.chiffres(8, _Teintes.rouge)),
        ),
        const Expanded(child: SizedBox(height: 3, child: ColoredBox(color: Color(0xFF7F1D1D)))),
      ],
    );
  }
}

/// Bouton pixel rouge, pour les actions à conséquence (déconnexion, suppression).
class _BoutonDanger extends StatelessWidget {
  final String libelle;
  final IconData icone;
  final VoidCallback onPressed;
  final bool plein;

  const _BoutonDanger(
      {super.key, required this.libelle, required this.icone, required this.onPressed, this.plein = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: libelle,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: plein ? const Color(0xFF7F1D1D) : PixelCouleurs.panneau,
            border: const Border(
              top: BorderSide(color: _Teintes.rougeVif, width: 3),
              left: BorderSide(color: _Teintes.rougeVif, width: 3),
              right: BorderSide(color: _Teintes.rougeVif, width: 3),
              bottom: BorderSide(color: Color(0xFF7F1D1D), width: 6),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // rétrécit plutôt que déborder dans une demi-largeur de dialogue
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, color: _Teintes.rouge, size: 20),
                const SizedBox(width: 8),
                Text(libelle, style: PixelTextes.corps(17, couleur: _Teintes.rouge, poids: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Suppression de compte (RGPD) ────────────────────────────────────────────

class _DeleteAccountButton extends StatelessWidget {
  final ProfileViewModel vm;

  const _DeleteAccountButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _BoutonDanger(
      key: const Key('btn_delete_account'),
      libelle: 'Supprimer mon compte',
      icone: Icons.delete_forever_outlined,
      onPressed: () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeleteAccountConfirmDialog(vm: vm),
      ),
    );
  }
}

// ─── Déconnexion ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final ProfileViewModel vm;

  const _LogoutButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _BoutonDanger(
      libelle: 'Se déconnecter',
      icone: Icons.logout,
      onPressed: () async {
        // Capture des ViewModels avant tout await (règle use_build_context_synchronously)
        final playerVm = context.read<PlayerViewModel>();
        final inventoryVm = context.read<InventoryViewModel>();
        final equipmentVm = context.read<EquipmentViewModel>();
        final catVm = context.read<CatViewModel>();

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => PixelDialogue(
            titre: 'Déconnexion',
            bord: _Teintes.rougeVif,
            contenu: Text('Veux-tu vraiment te déconnecter ?',
                textAlign: TextAlign.center, style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
            actions: [
              PixelBouton(libelle: 'Annuler', principal: false, onPressed: () => Navigator.pop(ctx, false)),
              _BoutonDanger(
                  libelle: 'Quitter', icone: Icons.logout, plein: true, onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        );
        if (confirmed == true) {
          // Déconnexion Supabase + purge Hive (dans AuthViewModel.signOut)
          await vm.signOut();
          // Remise à zéro des ViewModels en mémoire pour le prochain utilisateur
          playerVm.reset();
          await inventoryVm.reset();
          await equipmentVm.reset();
          catVm.reset();
        }
      },
    );
  }
}

// ─── Statistiques ────────────────────────────────────────────────────────────

class _StatisticsSection extends StatelessWidget {
  final ProfileViewModel vm;

  const _StatisticsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final completed = vm.completedQuests;

    // Quêtes par catégorie
    final byCategory = <String, int>{};
    for (final q in completed) {
      byCategory[q.category] = (byCategory[q.category] ?? 0) + 1;
    }
    final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCat = sortedCategories.isEmpty ? 1 : sortedCategories.first.value;

    // 7 derniers jours
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final byDay = <DateTime, int>{for (final d in days) d: 0};
    for (final q in completed) {
      if (q.completedAt == null) continue;
      final d = DateTime(q.completedAt!.year, q.completedAt!.month, q.completedAt!.day);
      if (byDay.containsKey(d)) byDay[d] = byDay[d]! + 1;
    }
    final maxDay = byDay.values.isEmpty ? 1 : byDay.values.reduce((a, b) => a > b ? a : b);
    final semaine = byDay.values.fold<int>(0, (a, b) => a + b);

    return _SectionCard(
      title: 'Statistiques',
      icon: Icons.insights,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('7 derniers jours', style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label: '$semaine quêtes terminées ces 7 derniers jours',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final count = byDay[d] ?? 0;
                final ratio = maxDay > 0 ? count / maxDay : 0.0;
                final isToday = d == DateTime(now.year, now.month, now.day);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (count > 0) Text('$count', style: PixelTextes.chiffres(8, PixelCouleurs.oracle)),
                        const SizedBox(height: 2),
                        Container(
                          height: 4 + (ratio * 12).round() * 4.0,
                          color:
                              isToday ? PixelCouleurs.or : PixelCouleurs.oracle.withValues(alpha: count > 0 ? 1 : .3),
                        ),
                        const SizedBox(height: 4),
                        Text(_dayLabel(d),
                            style: PixelTextes.corps(13,
                                couleur: isToday ? PixelCouleurs.orClair : PixelCouleurs.texteDoux,
                                poids: isToday ? FontWeight.w700 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (sortedCategories.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Par catégorie', style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
            const SizedBox(height: 8),
            ...sortedCategories.take(5).map((entry) {
              final ratio = maxCat > 0 ? entry.value / maxCat : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  label: '${entry.key} : ${entry.value}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(entry.key,
                            overflow: TextOverflow.ellipsis,
                            style: PixelTextes.corps(14, couleur: PixelCouleurs.texte)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: PixelJauge(valeur: ratio, couleur: PixelCouleurs.violet, hauteur: 12)),
                      const SizedBox(width: 8),
                      Text('${entry.value}', style: PixelTextes.chiffres(9, PixelCouleurs.violetClair)),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (vm.quests.isNotEmpty) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final total = vm.quests.length;
              final rate = completed.length / total;
              return MergeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Taux de réussite', style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
                    Text('${(rate * 100).round()} % (${completed.length} / $total)',
                        style: PixelTextes.corps(15, couleur: _Teintes.vert, poids: FontWeight.w700)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return labels[d.weekday - 1];
  }
}

// ─── Briques réutilisables ───────────────────────────────────────────────────

class _TexteVide extends StatelessWidget {
  final String texte;
  const _TexteVide(this.texte);

  @override
  Widget build(BuildContext context) => Text(texte, style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux));
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: PixelCouleurs.violetClair, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: PixelTextes.chiffres(10, PixelCouleurs.texte)),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
