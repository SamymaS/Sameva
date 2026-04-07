import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/supabase_config.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/api_validation_ai_service.dart';
import '../../../domain/services/claude_validation_ai_service.dart';
import '../../../domain/services/quest_rewards_calculator.dart';
import '../../../domain/services/validation_ai_service.dart';
import '../../../presentation/use_cases/complete_quest_use_case.dart';
import '../../../domain/services/cat_mood_service.dart';
import '../../../presentation/view_models/cat_view_model.dart';
import '../../../presentation/view_models/equipment_view_model.dart';
import '../../../presentation/view_models/inventory_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/cat/cat_reaction_overlay.dart';
import '../rewards/rewards_page.dart';

/// Page de validation de quête.
/// La validation directe est TOUJOURS possible.
/// La preuve photo/vidéo est optionnelle (analyse IA bonus).
class QuestValidationPage extends StatefulWidget {
  final Quest quest;

  const QuestValidationPage({super.key, required this.quest});

  @override
  State<QuestValidationPage> createState() => _QuestValidationPageState();
}

class _QuestValidationPageState extends State<QuestValidationPage> {
  late final ValidationAIService _validationService = () {
    final apiKey = SupabaseConfig.anthropicApiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      return ClaudeValidationAIService(apiKey: apiKey);
    }
    final url = SupabaseConfig.validationAiUrl;
    if (url != null && url.isNotEmpty) {
      return ApiValidationAIService(
        baseUrl: url,
        authToken: SupabaseConfig.supabaseAnonKey,
      );
    }
    return MockValidationAIService();
  }();

  bool _proofExpanded = false;
  bool _proofIsVideo = false;
  Uint8List? _proofImage;
  String? _proofVideoPath;
  bool _isAnalyzing = false;
  bool _isValidating = false;
  ValidationResult? _analysisResult;
  Timer? _timer;

  // Champ texte pour ValidationType.ai
  final _textProofCtrl = TextEditingController();

  bool get _hasDeadline => widget.quest.deadline != null;
  bool get _hasProof => _proofImage != null || _proofVideoPath != null;
  bool get _supportsPhoto =>
      widget.quest.validationType == ValidationType.photo;
  bool get _supportsAI =>
      widget.quest.validationType == ValidationType.ai;

  @override
  void initState() {
    super.initState();
    if (_hasDeadline) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textProofCtrl.dispose();
    super.dispose();
  }

  Duration? get _remainingTime {
    final deadline = widget.quest.deadline;
    if (deadline == null) return null;
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _proofImage = Uint8List.fromList(bytes);
        _proofVideoPath = null;
        _analysisResult = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    if (file != null) {
      setState(() {
        _proofVideoPath = file.path;
        _proofImage = null;
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeText() async {
    final text = _textProofCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isAnalyzing = true);
    try {
      final r = await _validationService.analyzeTextProof(
        quest: widget.quest,
        text: text,
      );
      if (mounted) setState(() => _analysisResult = r);
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Erreur analyse : $e',
          backgroundColor: AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _analyze() async {
    setState(() => _isAnalyzing = true);
    try {
      ValidationResult r;
      if (_proofImage != null) {
        r = await _validationService.analyzeProof(
          quest: widget.quest,
          imageBytes: _proofImage!,
        );
      } else {
        r = await _validationService.analyzeVideoProof(
          quest: widget.quest,
          videoPath: _proofVideoPath!,
        );
      }
      if (mounted) setState(() => _analysisResult = r);
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Erreur analyse : $e',
          backgroundColor: AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _completeAndNavigate() async {
    final questId = widget.quest.id;
    if (questId == null) return;

    setState(() => _isValidating = true);
    try {
      final useCase = CompleteQuestUseCase(
        questProvider: context.read<QuestViewModel>(),
        playerProvider: context.read<PlayerViewModel>(),
        equipmentProvider: context.read<EquipmentViewModel>(),
        inventoryProvider: context.read<InventoryViewModel>(),
      );
      final result = await useCase.execute(questId);
      final rewards = result.rewards;

      if (!mounted) return;

      // Réaction du chat après validation réussie
      final catProvider = context.read<CatViewModel>();
      final playerProvider = context.read<PlayerViewModel>();
      final cat = catProvider.mainCat;
      if (cat != null && mounted) {
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
        await _showLevelUpDialog(result.newLevel, rewards.experience);
        if (!mounted) return;
      }

      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(
        '/rewards',
        arguments: RewardsArgs(
          xpGained: rewards.experience,
          goldGained: rewards.gold,
          crystalsGained: rewards.crystals + result.crystalsFromLevelUp,
          leveledUp: result.didLevelUp,
          newLevel: result.newLevel,
          droppedItem: result.droppedItem,
          newAchievements: result.newAchievements,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotification.show(
        context,
        message: 'Erreur : $e',
        backgroundColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
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
    final base = QuestRewardsCalculator.calculateBaseRewards(widget.quest.difficulty);
    final xp = widget.quest.xpReward ?? base.experience;
    final gold = widget.quest.goldReward ?? base.gold;

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textMuted, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Validation',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── En-tête quête ───────────────────────────────────────
                  _QuestHeader(
                    quest: widget.quest,
                    rarityColor: rarityColor,
                  ),
                  const SizedBox(height: 20),

                  // ── Récompenses ─────────────────────────────────────────
                  _RewardsPreview(xp: xp, gold: gold),
                  const SizedBox(height: 16),

                  // ── Timer ───────────────────────────────────────────────
                  if (_hasDeadline) ...[
                    _TimerBlock(remaining: _remainingTime),
                    const SizedBox(height: 16),
                  ],

                  // ── Preuve texte IA (ValidationType.ai) ─────────────────
                  if (_supportsAI) ...[
                    _TextProofSection(
                      controller: _textProofCtrl,
                      isAnalyzing: _isAnalyzing,
                      analysisResult: _analysisResult,
                      onAnalyze: _analyzeText,
                      onClear: () => setState(() {
                        _textProofCtrl.clear();
                        _analysisResult = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Preuve photo (optionnelle) ───────────────────────────
                  if (_supportsPhoto) ...[
                    _ProofSection(
                      expanded: _proofExpanded,
                      hasProof: _hasProof,
                      proofIsVideo: _proofIsVideo,
                      proofImage: _proofImage,
                      isAnalyzing: _isAnalyzing,
                      analysisResult: _analysisResult,
                      onToggle: () =>
                          setState(() => _proofExpanded = !_proofExpanded),
                      onToggleType: (v) =>
                          setState(() => _proofIsVideo = v),
                      onPickImage: _pickImage,
                      onPickVideo: _pickVideo,
                      onClear: () => setState(() {
                        _proofImage = null;
                        _proofVideoPath = null;
                        _analysisResult = null;
                      }),
                      onAnalyze: _analyze,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // ── Bouton valider (toujours visible) ──────────────────────────
          _ValidateButton(
            isValidating: _isValidating,
            onValidate: _completeAndNavigate,
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
            const SizedBox(width: 12),
            const Icon(Icons.timer_outlined,
                color: AppColors.textMuted, size: 13),
            const SizedBox(width: 4),
            Text('${quest.estimatedDurationMinutes} min',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(width: 12),
            // Difficulté — points colorés
            Row(
              children: List.generate(
                5,
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

  const _RewardsPreview({required this.xp, required this.gold});

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
          const Text('Récompenses',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12)),
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

class _TimerBlock extends StatelessWidget {
  final Duration? remaining;

  const _TimerBlock({this.remaining});

  @override
  Widget build(BuildContext context) {
    if (remaining == null) return const SizedBox.shrink();
    final r = remaining!;
    final isOver = r == Duration.zero;

    final String text = isOver
        ? 'Échéance dépassée'
        : '${r.inHours.toString().padLeft(2, '0')}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';

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
              style: TextStyle(
                  color: isOver ? AppColors.error : AppColors.warning,
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
  final bool hasProof;
  final bool proofIsVideo;
  final Uint8List? proofImage;
  final bool isAnalyzing;
  final ValidationResult? analysisResult;
  final VoidCallback onToggle;
  final ValueChanged<bool> onToggleType;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onClear;
  final VoidCallback onAnalyze;

  const _ProofSection({
    required this.expanded,
    required this.hasProof,
    required this.proofIsVideo,
    required this.proofImage,
    required this.isAnalyzing,
    required this.analysisResult,
    required this.onToggle,
    required this.onToggleType,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onClear,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // En-tête cliquable
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajouter une preuve',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Optionnel',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Contenu expansible
          if (expanded) ...[
            Divider(
                height: 1,
                color: AppColors.textMuted.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!hasProof) ...[
                    // Toggle photo/vidéo
                    Row(
                      children: [
                        _MediaTypeButton(
                          label: 'Photo',
                          icon: Icons.camera_alt,
                          selected: !proofIsVideo,
                          onTap: () => onToggleType(false),
                        ),
                        const SizedBox(width: 8),
                        _MediaTypeButton(
                          label: 'Vidéo',
                          icon: Icons.videocam,
                          selected: proofIsVideo,
                          onTap: () => onToggleType(true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            proofIsVideo ? onPickVideo : onPickImage,
                        icon: Icon(proofIsVideo
                            ? Icons.videocam
                            : Icons.camera_alt),
                        label: Text(proofIsVideo
                            ? 'Enregistrer (max 30 s)'
                            : 'Prendre une photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryTurquoise,
                          side: const BorderSide(
                              color: AppColors.primaryTurquoise,
                              width: 1),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Aperçu preuve
                    if (proofImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          proofImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundNightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam,
                                color: AppColors.textMuted, size: 28),
                            SizedBox(width: 10),
                            Text('Vidéo enregistrée',
                                style: TextStyle(
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Résultat analyse
                    if (analysisResult != null) ...[
                      _AnalysisResult(result: analysisResult!),
                      const SizedBox(height: 12),
                    ],

                    // Actions
                    Row(
                      children: [
                        TextButton(
                          onPressed: onClear,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted),
                          child: const Text('Reprendre'),
                        ),
                        const Spacer(),
                        if (analysisResult == null)
                          FilledButton.icon(
                            onPressed: isAnalyzing ? null : onAnalyze,
                            icon: isAnalyzing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.psychology, size: 18),
                            label: Text(
                                isAnalyzing ? 'Analyse…' : 'Analyser'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondaryViolet,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                          ),
                      ],
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

class _MediaTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MediaTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                : AppColors.backgroundNightBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primaryTurquoise
                  : AppColors.textMuted.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppColors.primaryTurquoise
                      : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? AppColors.primaryTurquoise
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisResult extends StatelessWidget {
  final ValidationResult result;

  const _AnalysisResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final isValid = score >= 70;
    final isPartial = score >= 40 && score < 70;
    final color = isValid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;
    final label = isValid
        ? 'Preuve validée'
        : isPartial
            ? 'Preuve partielle'
            : 'Preuve insuffisante';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid
                    ? Icons.check_circle_outline
                    : isPartial
                        ? Icons.info_outline
                        : Icons.cancel_outlined,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const Spacer(),
              Text('$score/100',
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12)),
            ],
          ),
          if (result.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.explanation,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
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

// ─── Section preuve texte IA ──────────────────────────────────────────────────

class _TextProofSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnalyzing;
  final ValidationResult? analysisResult;
  final VoidCallback onAnalyze;
  final VoidCallback onClear;

  const _TextProofSection({
    required this.controller,
    required this.isAnalyzing,
    required this.analysisResult,
    required this.onAnalyze,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondaryViolet.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology,
                  color: AppColors.secondaryViolet, size: 18),
              SizedBox(width: 8),
              Text(
                'Validation IA',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Décris ce que tu as accompli — Claude évaluera si la quête est validée.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ex. J\'ai fait 30 min de sport, voici le détail...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.backgroundNightBlue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.textMuted.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.secondaryViolet),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (analysisResult != null) ...[
            _AnalysisResult(result: analysisResult!),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (controller.text.isNotEmpty || analysisResult != null)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted),
                  child: const Text('Effacer'),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isAnalyzing ? null : onAnalyze,
                icon: isAnalyzing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(isAnalyzing ? 'Analyse…' : 'Faire analyser'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryViolet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
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
