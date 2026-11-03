import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/audio/sons.dart';
import '../../widgets/pixel/mougibot_sprite.dart';
import '../../widgets/pixel/pixel_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/game_api.dart';
import '../../../presentation/use_cases/complete_quest_use_case.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../../presentation/view_models/ai_validation_credits_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_reaction_overlay.dart';
import '../../widgets/common/ai_credit_counter.dart';
import '../../widgets/common/no_ai_credits_sheet.dart';
import '../rewards/rewards_page.dart';

/// Page de validation de quête (Sprint 1 : le serveur décide).
///
/// - Quête à preuve (photo ou IA) : la seule voie est une photo prise avec
///   l'appareil et jugée par l'Oracle. Le verdict renvoyé est déjà appliqué
///   côté serveur : si la preuve est acceptée, la quête est close et
///   récompensée ; sinon, l'utilisateur peut reprendre une photo.
/// - Défi de capture : avant la photo, le serveur tire un geste et un nombre
///   à écrire sur un papier (« un pouce levé, et le nombre 47 »), valables
///   3 minutes, qui doivent apparaître sur la photo. Une ancienne photo, ou une
///   photo préparée à l'avance, ne peut pas les contenir : c'est ce qui prouve
///   que la photo vient d'être prise, quel que soit le client utilisé.
/// - Quête déclarative : bouton « Valider la quête » (`complete_quest`), à
///   récompense réduite, possible 10 minutes après la création.
class QuestValidationPage extends StatefulWidget {
  final Quest quest;

  /// API injectable (tests). En production : celle du [PlayerViewModel].
  final GameApi? gameApi;

  const QuestValidationPage({
    super.key,
    required this.quest,
    this.gameApi,
  });

  @override
  State<QuestValidationPage> createState() => _QuestValidationPageState();
}

class _QuestValidationPageState extends State<QuestValidationPage> {
  GameApi get _api => widget.gameApi ?? context.read<PlayerViewModel>().api;

  bool _proofExpanded = true;
  Uint8List? _proofImage;
  bool _isAnalyzing = false;
  bool _isValidating = false;
  OracleVerdict? _verdict;

  /// Défi affiché au joueur, et celui qui était affiché au moment de la photo.
  CaptureChallenge? _challenge;
  String? _captureChallengeId;
  bool _loadingChallenge = false;
  Timer? _ticker;

  /// Délai d'envoi toléré après l'expiration du défi (aligné sur le serveur).
  static const _uploadGrace = Duration(seconds: 60);

  static const _handsFreeKey = 'defi_sans_les_mains';

  /// Option d'accessibilité « sans les mains » : la préférence fait foi côté
  /// serveur ; Hive n'en garde qu'une copie pour l'affichage.
  bool get _handsFree {
    final c = _challenge;
    if (c != null) return c.handsFree;
    try {
      return Hive.box('settings').get(_handsFreeKey, defaultValue: false) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_requiresProof) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadChallenge());
      // Rafraîchit le compte à rebours du défi.
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _challenge != null) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Récupère le défi en cours (ou en tire un nouveau) auprès du serveur.
  Future<void> _loadChallenge({bool reroll = false}) async {
    final questId = widget.quest.id;
    if (questId == null || _loadingChallenge) return;
    setState(() => _loadingChallenge = true);
    try {
      final c = await _api.requestChallenge(questId, reroll: reroll);
      if (!mounted) return;
      // Une photo prise pour un autre défi ne prouve plus rien : on la retire
      // (constat Q18, sinon « Soumettre » restait actif avec l'ancienne photo).
      // Après un verdict, la photo reste affichée avec son résultat : seul
      // « Reprendre une photo » la remplace.
      final photoPerimee = _verdict == null &&
          _proofImage != null &&
          _captureChallengeId != c.id;
      setState(() {
        _challenge = c;
        if (photoPerimee) {
          _proofImage = null;
          _captureChallengeId = null;
        }
      });
      if (photoPerimee) {
        AppNotification.show(context, message: 'Nouveau défi : reprends une photo qui le montre.');
      }
    } on GameApiException catch (e) {
      if (!mounted) return;
      _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _setHandsFree(bool value) async {
    try {
      await _api.setChallengeHandsFree(value);
      try {
        await Hive.box('settings').put(_handsFreeKey, value);
      } catch (_) {}
    } catch (e) {
      if (mounted) _showError(e);
      return;
    }
    if (!mounted) return;
    // Le défi en cours n'est pas retiré pour autant : la préférence vaut pour
    // le prochain défi. S'il reste une relance et aucune photo, on l'utilise.
    final c = _challenge;
    if (c != null && !c.isExpired() && c.rerollsLeft > 0 && _proofImage == null) {
      await _loadChallenge(reroll: true);
    } else {
      AppNotification.show(context, message: 'Option enregistrée : elle s\'appliquera au prochain défi.');
      setState(() {});
    }
  }

  bool get _hasDeadline => widget.quest.deadline != null;

  /// Quête dont la validation passe obligatoirement par l'Oracle.
  bool get _requiresProof =>
      widget.quest.validationType == ValidationType.photo;

  Future<void> _pickImage() async {
    // Pas de photo sans défi valide : le défi doit être connu AVANT la prise.
    if (_challenge == null || _challenge!.isExpired()) {
      await _loadChallenge();
      if (!mounted || _challenge == null || _challenge!.isExpired()) return;
    }
    final challengeAtCapture = _challenge!;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      // Caméra restée ouverte trop longtemps : le serveur refuserait la photo.
      if (challengeAtCapture.isExpired(DateTime.now().subtract(_uploadGrace))) {
        AppNotification.show(
          context,
          message: 'Le défi a expiré pendant la prise de vue. Voici un nouveau défi.',
          backgroundColor: AppColors.warning,
        );
        setState(() => _challenge = null);
        await _loadChallenge();
        return;
      }
      setState(() {
        _proofImage = Uint8List.fromList(bytes);
        _captureChallengeId = challengeAtCapture.id;
        _verdict = null;
      });
    }
  }

  void _showError(Object e) {
    final message = e is GameApiException
        ? e.userMessage
        : 'Une erreur est survenue. Réessaie.';
    AppNotification.show(context, message: message, backgroundColor: AppColors.error);
  }

  /// Envoie la photo à l'Oracle. Le serveur consomme l'énergie, juge, et
  /// récompense si la preuve est acceptée.
  Future<void> _analyze() async {
    final questId = widget.quest.id;
    final image = _proofImage;
    final challengeId = _captureChallengeId;
    if (questId == null || image == null) return;
    if (challengeId == null) {
      // Photo prise sans défi connu : on la refait avec un défi.
      setState(() => _proofImage = null);
      await _loadChallenge();
      return;
    }

    final credits = context.read<AiValidationCreditsService>();
    if (!credits.canValidateWithAI()) {
      await showNoAiCreditsSheet(context);
      return;
    }

    setState(() => _isAnalyzing = true);
    unawaited(Sons.jouer(Son.oracleObserve));
    try {
      final verdict = await _api.submitProof(
        questId: questId,
        challengeId: challengeId,
        imageBase64: base64Encode(image),
      );
      if (!mounted) return;
      // Le défi est consommé : un nouvel essai demandera un nouveau défi.
      setState(() {
        _verdict = verdict;
        _challenge = null;
        _captureChallengeId = null;
      });
      unawaited(Sons.jouer(verdict.accepted ? Son.oracleAccepte : Son.oracleRefuse));
      if (!verdict.accepted) unawaited(_loadChallenge());
      unawaited(credits.refresh());
      final rewards = verdict.rewards;
      if (verdict.accepted && rewards != null) {
        await _celebrate(
          await _useCase().applyOracleVerdict(widget.quest, rewards),
        );
      }
    } on GameApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'energie_insuffisante') {
        unawaited(credits.refresh());
        await showNoAiCreditsSheet(context);
      } else if (e.code.startsWith('defi_')) {
        // Défi expiré ou déjà utilisé : la photo ne vaut plus, on recommence.
        setState(() {
          _proofImage = null;
          _captureChallengeId = null;
          _challenge = null;
        });
        _showError(e);
        unawaited(_loadChallenge());
      } else {
        _showError(e);
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  CompleteQuestUseCase _useCase() => CompleteQuestUseCase(
        questProvider: context.read<QuestViewModel>(),
        playerProvider: context.read<PlayerViewModel>(),
        inventoryProvider: context.read<InventoryViewModel>(),
      );

  /// Validation déclarative (quêtes sans preuve obligatoire).
  Future<void> _completeDeclarative() async {
    if (widget.quest.id == null) return;
    setState(() => _isValidating = true);
    try {
      final result = await _useCase().execute(widget.quest);
      await _celebrate(result);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  /// Affiche les récompenses accordées par le serveur.
  Future<void> _celebrate(CompleteQuestResult result) async {
    if (!mounted) return;
    final rewards = result.rewards;

    final catProvider = context.read<CatViewModel>();
    final playerProvider = context.read<PlayerViewModel>();
    final cat = catProvider.mainCat;
    if (cat != null) {
      final moral = playerProvider.stats?.moral ?? 0.7;
      final streak = playerProvider.stats?.streak ?? 0;
      final mood = CatMoodService.getMoodExpression(moral, streak);
      await showCatReactionOverlay(
        context,
        race: cat.race,
        equippedHat: cat.equippedHat,
        mood: mood,
        questResult: 'success',
      );
    }
    if (!mounted) return;

    if (result.didLevelUp) {
      await _showLevelUpDialog(result.newLevel, rewards.xp);
      if (!mounted) return;
    }

    // Remplace la validation par les récompenses (retour = liste des quêtes).
    context.pushReplacement(
      Routes.recompenses,
      extra: RewardsArgs(
        xpGained: rewards.xp,
        goldGained: rewards.gold,
        crystalsGained: rewards.crystals + result.crystalsFromLevelUp +
            rewards.streakMilestones.fold<int>(0, (sum, m) => sum + m.crystals),
        sealsGained: rewards.seals,
        leveledUp: result.didLevelUp,
        newLevel: result.newLevel,
        droppedItem: result.droppedItem,
        newAchievements: result.newAchievements,
      ),
    );
  }

  Future<void> _showLevelUpDialog(int newLevel, int xpGained) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LevelUpDialog(level: newLevel, xpGained: xpGained),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(widget.quest.rarity);
    // Aperçu : récompense de base calculée par le serveur à la création
    // (xp_reward / gold_reward). Le gain réel dépend du mode de validation.
    final xp = widget.quest.xpReward ?? 0;
    final gold = widget.quest.goldReward ?? 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textMuted, size: 18),
          onPressed: () => quitterEcran(context),
        ),
        title: const Text(
          'Validation',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        // Énergie de l'Oracle, visible pour les quêtes à preuve.
        actions: _requiresProof
            ? const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(child: AiCreditCounter()),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuestHeader(
                    quest: widget.quest,
                    rarityColor: rarityColor,
                  ),
                  const SizedBox(height: 20),
                  _RewardsPreview(xp: xp, gold: gold, declarative: !_requiresProof),
                  const SizedBox(height: 16),
                  if (_hasDeadline) ...[
                    _TimerBlock(deadline: widget.quest.deadline!),
                    const SizedBox(height: 16),
                  ],
                  if (_requiresProof) ...[
                    _ChallengeCard(
                      challenge: _challenge,
                      loading: _loadingChallenge,
                      handsFree: _handsFree,
                      photoTaken: _proofImage != null,
                      verdict: _verdict,
                      onReroll: () {
                        setState(() => _proofImage = null);
                        _loadChallenge(reroll: true);
                      },
                      onRefresh: () => _loadChallenge(),
                      onHandsFreeChanged: _setHandsFree,
                    ),
                    const SizedBox(height: 12),
                    _ProofSection(
                      expanded: _proofExpanded,
                      proofImage: _proofImage,
                      isAnalyzing: _isAnalyzing,
                      verdict: _verdict,
                      onToggle: () =>
                          setState(() => _proofExpanded = !_proofExpanded),
                      onPickImage: _pickImage,
                      onClear: () => setState(() {
                        _proofImage = null;
                        _verdict = null;
                      }),
                      onAnalyze: _analyze,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Validation déclarative uniquement pour les quêtes sans preuve.
          if (!_requiresProof)
            _ValidateButton(
              isValidating: _isValidating,
              onValidate: _completeDeclarative,
            ),
        ],
      ),
    );
  }

  Color _rarityColor(QuestRarity r) => switch (r) {
        QuestRarity.common => AppColors.rarityCommon,
        QuestRarity.uncommon => AppColors.rarityUncommon,
        QuestRarity.rare => AppColors.rarityRare,
        QuestRarity.epic => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic => AppColors.rarityMythic,
      };
}

// ── Widgets internes ──────────────────────────────────────────────────────────

/// Carte du défi de capture : ce qu'il faut montrer sur la photo et le temps
/// restant. Les quêtes à preuve ne se valident qu'avec ce défi visible.
class _ChallengeCard extends StatelessWidget {
  final CaptureChallenge? challenge;
  final bool loading;
  final bool handsFree;
  final bool photoTaken;
  final OracleVerdict? verdict;
  final VoidCallback onReroll;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onHandsFreeChanged;

  const _ChallengeCard({
    required this.challenge,
    required this.loading,
    required this.handsFree,
    required this.photoTaken,
    required this.verdict,
    required this.onReroll,
    required this.onRefresh,
    required this.onHandsFreeChanged,
  });

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final expired = c != null && c.isExpired();
    final missed = verdict?.rejectedForChallenge ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.primaryTurquoise.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryTurquoise.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  color: AppColors.primaryTurquoise, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Défi de l\'Oracle',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              if (c != null && !expired)
                Text(
                  _format(c.remaining()),
                  semanticsLabel: 'Temps restant ${c.remaining().inSeconds} secondes',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading && c == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (c == null || expired)
            Row(
              children: [
                Expanded(
                  child: Text(
                    expired ? 'Le défi a expiré.' : 'Aucun défi en cours.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: loading ? null : onRefresh, child: const Text('Nouveau défi')),
              ],
            )
          else ...[
            const Text(
              'Montre sur ta photo, à côté de ta preuve :',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (c.gesture != null)
              Row(
                children: [
                  const Icon(Icons.back_hand_outlined, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.gesture!,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.edit_note, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 8),
                const Text('Écrit sur un papier : ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                  c.number,
                  semanticsLabel: 'nombre ${c.number.split('').join(' ')}',
                  style: const TextStyle(
                      color: AppColors.primaryTurquoise,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ce défi prouve que ta photo vient d\'être prise.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (c.rerollsLeft > 0 && !photoTaken)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: loading ? null : onReroll,
                  child: const Text('Changer de défi (une fois)'),
                ),
              ),
          ],
          if (missed)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Ta preuve était bonne, mais MougiBot n\'a pas vu le geste et le nombre demandés. Reprends la photo avec le nouveau défi.',
                style: TextStyle(color: AppColors.warning, fontSize: 12, height: 1.4),
              ),
            ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Défis sans les mains (nombre seul)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              Switch(
                value: handsFree,
                onChanged: loading ? null : onHandsFreeChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestHeader extends StatelessWidget {
  final Quest quest;
  final Color rarityColor;

  const _QuestHeader({required this.quest, required this.rarityColor});

  String _rarityLabel(QuestRarity r) => switch (r) {
        QuestRarity.common => 'Commune',
        QuestRarity.uncommon => 'Peu commune',
        QuestRarity.rare => 'Rare',
        QuestRarity.epic => 'Épique',
        QuestRarity.legendary => 'Légendaire',
        QuestRarity.mythic => 'Mythique',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge rareté
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: rarityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            _rarityLabel(quest.rarity).toUpperCase(),
            style: TextStyle(
                color: rarityColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 10),
        // Titre
        Text(
          quest.title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2),
        ),
        const SizedBox(height: 6),
        // Méta
        Row(
          children: [
            const Icon(Icons.category_outlined,
                color: AppColors.textMuted, size: 13),
            const SizedBox(width: 4),
            Text(quest.category,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            // Durée affichée seulement si elle est connue (pas de « 0 min »).
            if (quest.estimatedDurationMinutes > 0) ...[
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text('${quest.estimatedDurationMinutes} min',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
            const SizedBox(width: 12),
            // Difficulté — points colorés
            Row(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < quest.difficulty
                        ? rarityColor
                        : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Description si présente
        if (quest.description != null && quest.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            quest.description!,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _RewardsPreview extends StatelessWidget {
  final int xp;
  final int gold;

  /// Validation déclarative : la récompense est réduite de moitié.
  final bool declarative;

  const _RewardsPreview({required this.xp, required this.gold, this.declarative = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryTurquoise.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_outlined,
              color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Text(declarative ? 'Récompenses de base (×0,5 sans preuve)' : 'Récompenses de base',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const Spacer(),
          const Icon(Icons.star, color: AppColors.primaryTurquoise, size: 16),
          const SizedBox(width: 4),
          Text('+$xp XP',
              style: const TextStyle(
                  color: AppColors.primaryTurquoise,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 16),
          const Icon(Icons.monetization_on, color: AppColors.gold, size: 16),
          const SizedBox(width: 4),
          Text('+$gold',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

class _TimerBlock extends StatefulWidget {
  final DateTime deadline;

  const _TimerBlock({required this.deadline});

  @override
  State<_TimerBlock> createState() => _TimerBlockState();
}

class _TimerBlockState extends State<_TimerBlock> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(_updateRemaining);
      },
    );
  }

  void _updateRemaining() {
    final diff = widget.deadline.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _remaining;
    final isOver = r == Duration.zero;

    final String text =
        '${r.inHours.toString().padLeft(2, '0')}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isOver ? AppColors.error : AppColors.warning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOver ? AppColors.error : AppColors.warning)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOver ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: isOver ? AppColors.error : AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            isOver ? 'Échéance dépassée' : 'Temps restant',
            style: TextStyle(
                color: isOver ? AppColors.error : AppColors.warning,
                fontSize: 13),
          ),
          if (!isOver) ...[
            const Spacer(),
            Text(
              text,
              style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProofSection extends StatelessWidget {
  final bool expanded;
  final Uint8List? proofImage;
  final bool isAnalyzing;
  final OracleVerdict? verdict;
  final VoidCallback onToggle;
  final VoidCallback onPickImage;
  final VoidCallback onClear;
  final VoidCallback onAnalyze;

  const _ProofSection({
    required this.expanded,
    required this.proofImage,
    required this.isAnalyzing,
    required this.verdict,
    required this.onToggle,
    required this.onPickImage,
    required this.onClear,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final hasProof = proofImage != null;
    // Style pixel (maquette « Oracle · MougiBot observe ») : cadre épais, ombre
    // franche ; le turquoise est réservé à l'Oracle.
    return PixelCadre(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, color: PixelCouleurs.oracle, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preuve photo', style: PixelTextes.corps(17, poids: FontWeight.w700)),
                        Text('Requise : MougiBot décide de la validation',
                            style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: PixelCouleurs.texteDoux, size: 22),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 3, thickness: 3, color: PixelCouleurs.trait),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!hasProof)
                    PixelBouton(libelle: 'Prendre une photo', principal: false, onPressed: onPickImage)
                  else ...[
                    _CadrePhoto(image: proofImage!, analyse: isAnalyzing),
                    const SizedBox(height: 12),
                    if (isAnalyzing) ...[
                      const _OracleObserve(),
                      const SizedBox(height: 12),
                    ],
                    if (verdict != null) ...[
                      _AnalysisResult(verdict: verdict!),
                      const SizedBox(height: 12),
                    ],
                    if (verdict == null)
                      PixelBouton(
                        libelle: isAnalyzing ? 'L\'Oracle observe…' : 'Soumettre à l\'Oracle',
                        onPressed: isAnalyzing ? null : onAnalyze,
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      // Ouvre directement la caméra (la nouvelle photo remplace l'ancienne).
                      onPressed: isAnalyzing ? null : onPickImage,
                      style: TextButton.styleFrom(
                        foregroundColor: PixelCouleurs.texteDoux,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: PixelTextes.corps(16, poids: FontWeight.w600),
                      ),
                      child: const Text('Reprendre une photo'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Photo de preuve dans un cadre turquoise ; pendant l'analyse, une ligne de
/// balayage la parcourt en 12 paliers (1,8 s) entre quatre coins de visée.
class _CadrePhoto extends StatefulWidget {
  final Uint8List image;
  final bool analyse;
  const _CadrePhoto({required this.image, required this.analyse});

  @override
  State<_CadrePhoto> createState() => _CadrePhotoState();
}

class _CadrePhotoState extends State<_CadrePhoto> with SingleTickerProviderStateMixin {
  late final AnimationController _balayage =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.analyse) _balayage.repeat();
  }

  @override
  void didUpdateWidget(_CadrePhoto old) {
    super.didUpdateWidget(old);
    if (widget.analyse && !_balayage.isAnimating) _balayage.repeat();
    if (!widget.analyse && _balayage.isAnimating) _balayage.stop();
  }

  @override
  void dispose() {
    _balayage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hauteur = 220.0;
    return Container(
      height: hauteur,
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: PixelCouleurs.oracle, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black, offset: Offset(0, 4))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(widget.image, fit: BoxFit.cover, gaplessPlayback: true),
          if (widget.analyse) ...[
            const ColoredBox(color: Color(0x660A0620)),
            AnimatedBuilder(
              animation: _balayage,
              builder: (_, __) => Align(
                alignment: Alignment(0, -1 + 2 * parPaliers(_balayage.value, 12)),
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: PixelCouleurs.oracle,
                    border: Border.symmetric(horizontal: BorderSide(color: AppColors.crystalBlue, width: 2)),
                  ),
                ),
              ),
            ),
            for (final coin in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
              Align(alignment: coin, child: _CoinVisee(coin: coin)),
          ],
        ],
      ),
    );
  }
}

class _CoinVisee extends StatelessWidget {
  final Alignment coin;
  const _CoinVisee({required this.coin});

  @override
  Widget build(BuildContext context) {
    const trait = BorderSide(color: AppColors.crystalBlue, width: 4);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          border: Border(
            top: coin.y < 0 ? trait : BorderSide.none,
            bottom: coin.y > 0 ? trait : BorderSide.none,
            left: coin.x < 0 ? trait : BorderSide.none,
            right: coin.x > 0 ? trait : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// MougiBot qui observe, avec sa bulle « L'Oracle observe… ».
class _OracleObserve extends StatelessWidget {
  const _OracleObserve();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const MougiBotSprite(etat: EtatMougiBot.observe, cote: 112),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: PixelCouleurs.oracle, offset: Offset(4, 4))],
          ),
          child: Text('L\'Oracle observe…',
              style: PixelTextes.corps(16, couleur: PixelCouleurs.nuit, poids: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Verdict de l'Oracle. Le seuil vient du serveur (`threshold`).
class _AnalysisResult extends StatelessWidget {
  final OracleVerdict verdict;

  const _AnalysisResult({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final score = verdict.score;
    final isValid = verdict.accepted;
    // Refus dû au seul défi de capture : la preuve était bonne, c'est le geste
    // ou le nombre qui manquait. Le dire clairement, sans parler de netteté.
    final missedChallenge = verdict.rejectedForChallenge;
    final isPartial = !isValid && (missedChallenge || score >= verdict.threshold - 30);
    final color = isValid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;
    final label = isValid
        ? 'Preuve validée'
        : missedChallenge
            ? 'Défi non visible sur la photo'
            : isPartial
                ? 'Presque ! Reprends une photo plus nette'
                : 'Preuve insuffisante';

    // Style pixel (maquette « Oracle · Verdict accepté ») : MougiBot qui réagit,
    // tampon du verdict, barre de confiance avec le seuil du serveur.
    return PixelCadre(
      bord: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MougiBotSprite(etat: isValid ? EtatMougiBot.accepte : EtatMougiBot.refuse, cote: 96),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PixelTextes.corps(17, couleur: color, poids: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('$score/100', style: PixelTextes.chiffres(14, color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Confiance $score sur 100, seuil ${verdict.threshold}',
            excludeSemantics: true,
            child: PixelBarreSeuil(valeur: score / 100, seuil: verdict.threshold / 100, couleur: color),
          ),
          const SizedBox(height: 6),
          Text('Seuil de l\'Oracle : ${verdict.threshold}',
              style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
          if (verdict.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('«\u00A0${verdict.explanation}\u00A0»', style: PixelTextes.corps(15)),
          ],
        ],
      ),
    );
  }
}

class _ValidateButton extends StatelessWidget {
  final bool isValidating;
  final VoidCallback onValidate;

  const _ValidateButton(
      {required this.isValidating, required this.onValidate});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.backgroundNightBlue,
        border: Border(
          top: BorderSide(
              color: AppColors.textMuted.withValues(alpha: 0.1)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: isValidating ? null : onValidate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTurquoise,
            foregroundColor: AppColors.backgroundNightBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          child: isValidating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.backgroundNightBlue),
                )
              : const Text('Valider la quête'),
        ),
      ),
    );
  }
}

// ─── Dialog Level-Up ─────────────────────────────────────────────────────────

class _LevelUpDialog extends StatefulWidget {
  final int level;
  final int xpGained;

  const _LevelUpDialog({required this.level, required this.xpGained});

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _glow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.backgroundDeepViolet,
                  AppColors.backgroundDarkPanel
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    AppColors.gold.withValues(alpha: 0.6 + _glow.value * 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: _glow.value * 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    color: AppColors.gold, size: 56 + _glow.value * 8),
                const SizedBox(height: 16),
                const Text(
                  'NIVEAU SUPÉRIEUR !',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Niveau ${widget.level}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${widget.xpGained} XP',
                  style: const TextStyle(
                    color: AppColors.primaryTurquoise,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.backgroundNightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
