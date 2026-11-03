import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quest_model.dart';
import '../../../domain/services/api_quest_suggestion_service.dart';
import '../../../domain/services/quest_suggestion_service.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/player_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_notification.dart';
import '../../widgets/pixel/mougibot_sprite.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Page de génération de quêtes personnalisées via MougiBot (Edge Function
/// suggest-quests). Style pixel : MougiBot et sa bulle, cartes à bord épais.
class GenerateQuestsPage extends StatefulWidget {
  const GenerateQuestsPage({super.key});

  @override
  State<GenerateQuestsPage> createState() => _GenerateQuestsPageState();
}

class _GenerateQuestsPageState extends State<GenerateQuestsPage> {
  List<Quest> _quests = [];
  bool _isLoading = false;
  String? _error;
  final Set<int> _addingIndices = {};
  final Set<int> _addedIndices = {};

  QuestSuggestionService _buildService() => ApiQuestSuggestionService();

  Future<void> _generate() async {
    final player = context.read<PlayerViewModel>().stats;
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) {
      setState(() => _error = 'Utilisateur non connecté.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _quests = [];
      _addedIndices.clear();
    });

    try {
      final service = _buildService();
      final quests = await service.suggestQuests(
        userId: userId,
        request: QuestSuggestionRequest(
          playerLevel: player?.level ?? 1,
          streak: player?.streak ?? 0,
          totalQuestsCompleted: player?.totalQuestsCompleted ?? 0,
        ),
      );
      if (mounted) setState(() => _quests = quests);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is QuestSuggestionException
            ? e.userMessage
            : 'Mougi n\'a pas pu générer de quêtes. Vérifie ta connexion et réessaie.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addQuest(int index) async {
    setState(() => _addingIndices.add(index));
    try {
      await context.read<QuestViewModel>().addQuest(_quests[index]);
      if (mounted) {
        setState(() => _addedIndices.add(index));
        AppNotification.show(context, message: '« ${_quests[index].title} » ajoutée !');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(
          context,
          message: 'Erreur : $e',
          backgroundColor: AppColors.error,
        );
      }
    } finally {
      if (mounted) setState(() => _addingIndices.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerViewModel>().stats;
    final etat = _isLoading
        ? EtatMougiBot.observe
        : _error != null
            ? EtatMougiBot.refuse
            : _quests.isNotEmpty
                ? EtatMougiBot.accepte
                : EtatMougiBot.repos;
    final bulle = _isLoading
        ? 'MougiBot réfléchit…'
        : _error != null
            ? 'Oups, je n\'ai rien trouvé.'
            : _quests.isNotEmpty
                ? 'Voici mes idées pour toi !'
                : 'Je te propose 3 quêtes adaptées à ton profil.';

    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: pixelBarre('Générer avec IA'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                MougiBotSprite(etat: etat, cote: 96),
                const SizedBox(width: 8),
                Expanded(child: _Bulle(texte: bulle)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSummaryCard(
            level: player?.level ?? 1,
            streak: player?.streak ?? 0,
            totalCompleted: player?.totalQuestsCompleted ?? 0,
          ),
          const SizedBox(height: 16),
          PixelBouton(
            libelle: _isLoading
                ? 'Génération en cours…'
                : _quests.isEmpty
                    ? 'Générer 3 quêtes'
                    : 'Générer d\'autres quêtes',
            onPressed: _isLoading ? null : _generate,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            PixelCadre(
              bord: const Color(0xFFFCA5A5),
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: PixelTextes.corps(15, couleur: const Color(0xFFFCA5A5))),
            ),
          ],
          for (var i = 0; i < _quests.length; i++) ...[
            const SizedBox(height: 12),
            _QuestCard(
              quest: _quests[i],
              isAdding: _addingIndices.contains(i),
              isAdded: _addedIndices.contains(i),
              onAdd: () => _addQuest(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bulle de dialogue de MougiBot : fond clair, ombre franche turquoise.
class _Bulle extends StatelessWidget {
  const _Bulle({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: PixelCouleurs.oracle, offset: Offset(4, 4))],
      ),
      child: Text(texte, style: PixelTextes.corps(16, couleur: PixelCouleurs.nuit, poids: FontWeight.w700)),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.level,
    required this.streak,
    required this.totalCompleted,
  });

  final int level;
  final int streak;
  final int totalCompleted;

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Niveau', value: '$level'),
          _Stat(label: 'Série', value: '${streak}j'),
          _Stat(label: 'Quêtes', value: '$totalCompleted'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: PixelTextes.chiffres(14, PixelCouleurs.orClair)),
          const SizedBox(height: 6),
          Text(label, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.isAdding,
    required this.isAdded,
    required this.onAdd,
  });

  final Quest quest;
  final bool isAdding;
  final bool isAdded;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return PixelCadre(
      bord: isAdded ? const Color(0xFF15803D) : PixelCouleurs.oracle,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(quest.title, style: PixelTextes.corps(17, poids: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              _DifficultyBadge(difficulty: quest.difficulty),
            ],
          ),
          if (quest.description != null && quest.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(quest.description!, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Info(icone: Icons.category_outlined, texte: quest.category),
              _Info(icone: Icons.timer_outlined, texte: '${quest.estimatedDurationMinutes} min'),
              _Info(icone: Icons.repeat, texte: _frequencyLabel(quest.frequency)),
            ],
          ),
          const SizedBox(height: 12),
          PixelBouton(
            libelle: isAdded
                ? 'Ajoutée'
                : isAdding
                    ? 'Ajout…'
                    : 'Ajouter',
            principal: !isAdded,
            onPressed: isAdding || isAdded ? null : onAdd,
          ),
        ],
      ),
    );
  }

  String _frequencyLabel(QuestFrequency f) => switch (f) {
        QuestFrequency.oneOff => 'Unique',
        QuestFrequency.daily => 'Quotidien',
        QuestFrequency.weekly => 'Hebdo',
        QuestFrequency.monthly => 'Mensuel',
      };
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 14, color: PixelCouleurs.texteDoux),
        const SizedBox(width: 4),
        Text(texte, style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
      ],
    );
  }
}

/// Difficulté en blocs or (comme dans le formulaire de création).
class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final d = difficulty.clamp(1, 4);
    return Semantics(
      label: 'Difficulté $d sur 4',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 3),
              color: i < d ? PixelCouleurs.or : PixelCouleurs.trait,
            ),
        ],
      ),
    );
  }
}
