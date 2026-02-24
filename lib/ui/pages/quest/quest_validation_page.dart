import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/supabase_config.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/api_validation_ai_service.dart';
import '../../../domain/services/validation_ai_service.dart';
import '../../../domain/use_cases/complete_quest_use_case.dart';
import '../../../presentation/providers/equipment_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';

/// Validation de quête : timer si contrainte de temps, preuve photo ou vidéo.
class QuestValidationPage extends StatefulWidget {
  final Quest quest;

  const QuestValidationPage({super.key, required this.quest});

  @override
  State<QuestValidationPage> createState() => _QuestValidationPageState();
}

class _QuestValidationPageState extends State<QuestValidationPage> {
  late final ValidationAIService _validationService = () {
    final url = SupabaseConfig.validationAiUrl;
    if (url != null && url.isNotEmpty) {
      return ApiValidationAIService(
        baseUrl: url,
        authToken: SupabaseConfig.supabaseAnonKey,
      );
    }
    return MockValidationAIService();
  }();

  bool _consentGiven = false;
  bool _mediaConsent = false;
  bool _proofIsVideo = false;
  Uint8List? _proofImage;
  String? _proofVideoPath;
  bool _isAnalyzing = false;
  bool _isValidating = false;
  ValidationResult? _result;
  Timer? _timer;

  bool get _isPhotoValidation => widget.quest.validationType == ValidationType.photo;
  bool get _hasDeadline => widget.quest.deadline != null;
  bool get _hasProof => _proofImage != null || _proofVideoPath != null;

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
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _proofImage = Uint8List.fromList(bytes);
        _proofVideoPath = null;
        _result = null;
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
        _result = null;
      });
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
      if (mounted) setState(() => _result = r);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _clearProof() {
    setState(() {
      _proofImage = null;
      _proofVideoPath = null;
      _result = null;
    });
  }

  /// P0.1 + P2.1 : utilise CompleteQuestUseCase — calcul des récompenses
  /// via QuestRewardsCalculator (timing + streak), plus de contournement.
  Future<void> _completeAndNavigate() async {
    final questId = widget.quest.id;
    if (questId == null) return;

    setState(() => _isValidating = true);
    try {
      final useCase = CompleteQuestUseCase(
        questProvider: context.read<QuestProvider>(),
        playerProvider: context.read<PlayerProvider>(),
        equipmentProvider: context.read<EquipmentProvider>(),
      );
      final result = await useCase.execute(questId);
      final rewards = result.rewards;

      if (!mounted) return;

      // Dialog level-up avant de naviguer
      if (result.didLevelUp) {
        await _showLevelUpDialog(result.newLevel, rewards.experience);
        if (!mounted) return;
      }

      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/rewards');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quête validée · +${rewards.experience} XP · +${rewards.gold} or'
            '${rewards.hasBonus ? ' (bonus ×${rewards.multiplier.toStringAsFixed(1)})' : ''}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation : $e'),
          backgroundColor: AppColors.error,
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Valider la quête')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.quest.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.quest.category} · ${widget.quest.estimatedDurationMinutes} min',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_hasDeadline) ...[
              const SizedBox(height: 16),
              _TimerBlock(remaining: _remainingTime),
            ],
            const SizedBox(height: 24),
            if (_isPhotoValidation) ...[
              const Text('Preuve visuelle', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                'Cadrez la zone liée à la quête (ex : lit, bureau, pièce rangée). '
                'Photo ou courte vidéo pour montrer la tâche réalisée.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _mediaConsent,
                onChanged: (v) => setState(() => _mediaConsent = v ?? false),
                title: const Text(
                  "J'accepte que la preuve soit utilisée uniquement pour la validation puis supprimée.",
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              if (!_hasProof) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Photo'), icon: Icon(Icons.camera_alt)),
                    ButtonSegment(value: true, label: Text('Vidéo'), icon: Icon(Icons.videocam)),
                  ],
                  selected: {_proofIsVideo},
                  onSelectionChanged: (s) => setState(() => _proofIsVideo = s.first),
                ),
                const SizedBox(height: 12),
                if (_mediaConsent)
                  _proofIsVideo
                      ? OutlinedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.videocam),
                          label: const Text('Prendre une vidéo (max 30 s)'),
                        )
                      : OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre une photo'),
                        ),
              ] else ...[
                if (_proofImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _proofImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, size: 48),
                        SizedBox(height: 8),
                        Text('Vidéo enregistrée'),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clearProof,
                      child: const Text('Reprendre'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isAnalyzing || !_mediaConsent ? null : _analyze,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.psychology),
                      label: Text(_isAnalyzing ? 'Analyse…' : 'Analyser'),
                    ),
                  ],
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                _ResultBlock(
                  result: _result!,
                  isValidating: _isValidating,
                  onValidate: _completeAndNavigate,
                ),
              ],
            ] else ...[
              CheckboxListTile(
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                title: const Text('Je confirme avoir réalisé cette quête.'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              Text(
                'Récompense réduite pour la validation simple.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: (_consentGiven && !_isValidating) ? _completeAndNavigate : null,
                child: _isValidating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Valider la quête'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerBlock extends StatelessWidget {
  const _TimerBlock({this.remaining});
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining == null) return const SizedBox.shrink();
    final r = remaining!;
    final isOver = r == Duration.zero;
    final text = isOver
        ? 'Échéance dépassée'
        : 'Temps restant : ${r.inHours}:${(r.inMinutes % 60).toString().padLeft(2, '0')}:${(r.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isOver
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.schedule : Icons.timer_outlined,
            color: isOver
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isOver
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({
    required this.result,
    required this.onValidate,
    required this.isValidating,
  });

  final ValidationResult result;
  final VoidCallback onValidate;
  final bool isValidating;

  @override
  Widget build(BuildContext context) {
    final int score = result.score;
    final bool isValid = score >= 70;
    final bool isPartial = score >= 40 && score < 70;
    final String label =
        isValid ? 'Validée' : isPartial ? 'Validation partielle' : 'Refusée';
    final Color color =
        isValid ? AppColors.success : isPartial ? AppColors.warning : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : isPartial ? Icons.hourglass_bottom : Icons.cancel,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Score : ${result.score}/100 (seuil 70)',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(result.explanation, style: Theme.of(context).textTheme.bodySmall),
        if (isValid) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isValidating ? null : onValidate,
              child: isValidating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Valider et recevoir les récompenses'),
            ),
          ),
        ],
      ],
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
                colors: [AppColors.backgroundDeepViolet, AppColors.backgroundDarkPanel],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6 + _glow.value * 0.4),
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
                // Étoile animée
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 56 + _glow.value * 8,
                ),
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
                    child: const Text(
                      'Continuer',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
