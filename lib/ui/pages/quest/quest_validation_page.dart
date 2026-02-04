import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/quest_model.dart';
import '../../../domain/services/validation_ai_service.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/player_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../theme/app_colors.dart';

/// Validation de quête — Jakob (formulaire familier), Hick (1 action principale : Valider ou Prendre photo).
/// Fitts : boutons larges.
class QuestValidationPage extends StatefulWidget {
  final Quest quest;

  const QuestValidationPage({super.key, required this.quest});

  @override
  State<QuestValidationPage> createState() => _QuestValidationPageState();
}

class _QuestValidationPageState extends State<QuestValidationPage> {
  final _validationService = MockValidationAIService();
  bool _consentGiven = false;
  bool _mediaConsent = false;
  Uint8List? _proofImage;
  bool _isAnalyzing = false;
  ValidationResult? _result;

  bool get _isPhotoValidation => widget.quest.validationType == ValidationType.photo;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _proofImage = Uint8List.fromList(bytes);
        _result = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_proofImage == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final r = await _validationService.analyzeProof(
        quest: widget.quest,
        imageBytes: _proofImage!,
      );
      if (mounted) setState(() => _result = r);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _completeAndNavigate() async {
    final questId = widget.quest.id;
    final userId = context.read<AuthProvider>().userId;
    if (questId == null || userId == null) return;

    await context.read<QuestProvider>().completeQuest(questId);
    final xp = widget.quest.xpReward ?? 10;
    await context.read<PlayerProvider>().addExperience(userId, xp);
    await context.read<PlayerProvider>().updateStreak(userId);

    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/rewards');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quête validée · +$xp XP')),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.quest.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_isPhotoValidation) ...[
              const Text('Preuve visuelle', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(
                'Cadrez la zone liée à la quête (ex : lit, bureau, pièce rangée). '
                'Assurez-vous que l\'action réalisée soit clairement visible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _mediaConsent,
                onChanged: (v) => setState(() => _mediaConsent = v ?? false),
                title: const Text(
                  'J\'accepte que la photo soit utilisée uniquement pour la validation puis supprimée.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              if (_proofImage == null)
                OutlinedButton.icon(
                  onPressed: _mediaConsent ? _pickImage : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Prendre une photo'),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _proofImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _proofImage = null),
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
                _ResultBlock(result: _result!, onValidate: _completeAndNavigate),
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
                onPressed: _consentGiven ? _completeAndNavigate : null,
                child: const Text('Valider la quête'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.result, required this.onValidate});

  final ValidationResult result;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    // Classification simple : >=70 validée, 40–69 validation partielle, <40 refusée.
    final int score = result.score;
    final bool isValid = score >= 70;
    final bool isPartial = score >= 40 && score < 70;
    final String label = isValid
        ? 'Validée'
        : isPartial
            ? 'Validation partielle'
            : 'Refusée';
    final Color color = isValid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isValid
                  ? Icons.check_circle
                  : isPartial
                      ? Icons.hourglass_bottom
                      : Icons.cancel,
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
        Text('Score : ${result.score}/100 (seuil 70)', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text(result.explanation, style: Theme.of(context).textTheme.bodySmall),
        if (isValid) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onValidate,
              child: const Text('Valider et recevoir les récompenses'),
            ),
          ),
        ],
      ],
    );
  }
}
