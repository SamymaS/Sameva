import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/quest_templates.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../utils/app_notification.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Mode « Par thème » : choix du thème (Sport, Loisir, Maison) puis liste de
/// tâches préconfigurées. Style pixel : cartes à bord épais, durée en blocs.
class CreateQuestByThemePage extends StatefulWidget {
  const CreateQuestByThemePage({super.key});

  @override
  State<CreateQuestByThemePage> createState() => _CreateQuestByThemePageState();
}

class _CreateQuestByThemePageState extends State<CreateQuestByThemePage> {
  static const List<int> _durationOptions = [5, 10, 15, 20, 25, 30, 45, 60];

  String? _selectedTheme;

  @override
  Widget build(BuildContext context) {
    final templates = _selectedTheme == null
        ? <QuestTemplate>[]
        : questTemplatesByTheme[_selectedTheme]!;

    return PopScope(
      // Retour système depuis la liste : revient à la grille des thèmes.
      canPop: _selectedTheme == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selectedTheme = null);
      },
      child: Scaffold(
        backgroundColor: PixelCouleurs.nuit,
        appBar: pixelBarre(
          _selectedTheme ?? 'Choisir un thème',
          leading: _selectedTheme != null
              ? IconButton(
                  tooltip: 'Retour aux thèmes',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedTheme = null),
                )
              : null,
        ),
        body: _selectedTheme == null ? _buildThemeGrid() : _buildTemplateList(templates),
      ),
    );
  }

  Widget _buildThemeGrid() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Choisis un thème pour voir les tâches préconfigurées.',
            style: PixelTextes.corps(17, couleur: PixelCouleurs.texteDoux)),
        const SizedBox(height: 16),
        for (final theme in themeCategories)
          _CarteTheme(
            icone: _iconForTheme(theme),
            accent: _accentForTheme(theme),
            titre: theme,
            nombre: questTemplatesByTheme[theme]?.length ?? 0,
            onTap: () => setState(() => _selectedTheme = theme),
          ),
      ],
    );
  }

  IconData _iconForTheme(String theme) {
    switch (theme) {
      case 'Sport':
        return Icons.fitness_center;
      case 'Loisir':
        return Icons.palette_outlined;
      case 'Maison':
        return Icons.home_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _accentForTheme(String theme) {
    switch (theme) {
      case 'Sport':
        return const Color(0xFFB45309);
      case 'Loisir':
        return PixelCouleurs.violet;
      case 'Maison':
        return const Color(0xFF15803D);
      default:
        return PixelCouleurs.trait;
    }
  }

  Widget _buildTemplateList(List<QuestTemplate> templates) {
    final accent = _accentForTheme(_selectedTheme!);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = templates[index];
        final photo = t.validationType == ValidationType.photo;
        return MergeSemantics(
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => _showCreateDialog(t),
              behavior: HitTestBehavior.opaque,
              child: PixelCadre(
                bord: accent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: PixelTextes.corps(17, poids: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('${t.defaultDurationMinutes} min',
                                  style: PixelTextes.chiffres(9, PixelCouleurs.orClair)),
                              const SizedBox(width: 10),
                              Icon(photo ? Icons.photo_camera_outlined : Icons.check_box_outlined,
                                  size: 14, color: photo ? PixelCouleurs.oracle : PixelCouleurs.texteDoux),
                              const SizedBox(width: 4),
                              Text(photo ? 'Preuve photo' : 'Validation simple',
                                  style: PixelTextes.corps(14,
                                      couleur: photo ? PixelCouleurs.oracle : PixelCouleurs.texteDoux)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      color: PixelCouleurs.or,
                      child: const Icon(Icons.add, color: PixelCouleurs.nuit, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateDialog(QuestTemplate template) async {
    int duration = _durationOptions.contains(template.defaultDurationMinutes)
        ? template.defaultDurationMinutes
        : 15;
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return PixelDialogue(
              titre: template.title,
              contenu: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Durée estimée', style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in _durationOptions)
                        PixelChoix(
                          libelle: '$m min',
                          choisi: m == duration,
                          onTap: () => setDialogState(() => duration = m),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                PixelBouton(
                  libelle: 'Annuler',
                  principal: false,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                PixelBouton(
                  libelle: 'Créer',
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            );
          },
        );
      },
    );
    if (created != true || !mounted) return;
    await _createQuestFromTemplate(template, duration);
  }

  Future<void> _createQuestFromTemplate(QuestTemplate template, int durationMinutes) async {
    final userId = context.read<AuthViewModel>().userId;
    if (userId == null) return;

    final now = DateTime.now();
    final deadline = DateTime(now.year, now.month, now.day, 23, 59);

    final quest = Quest(
      userId: userId,
      title: template.title,
      estimatedDurationMinutes: durationMinutes,
      frequency: QuestFrequency.oneOff,
      difficulty: 1,
      category: template.category,
      rarity: QuestRarity.common,
      status: QuestStatus.active,
      validationType: template.validationType,
      deadline: deadline,
    );

    await context.read<QuestViewModel>().addQuest(quest);
    if (!mounted) return;
    // Pop unique avec résultat `true` : CreateQuestChoicePage reçoit le signal
    // et se ferme à son tour.
    Navigator.of(context).pop(true);
    AppNotification.show(context, message: 'Quête créée');
  }
}

class _CarteTheme extends StatelessWidget {
  final IconData icone;
  final Color accent;
  final String titre;
  final int nombre;
  final VoidCallback onTap;

  const _CarteTheme({
    required this.icone,
    required this.accent,
    required this.titre,
    required this.nombre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: PixelCadre(
              bord: accent,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PixelCouleurs.panneauProfond,
                      border: Border.all(color: accent, width: 2),
                    ),
                    child: Icon(icone, color: PixelCouleurs.orClair, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: PixelTextes.chiffres(12, PixelCouleurs.texte)),
                        const SizedBox(height: 6),
                        Text('$nombre tâche${nombre > 1 ? 's' : ''}',
                            style: PixelTextes.corps(15, couleur: PixelCouleurs.texteDoux)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: PixelCouleurs.texteDoux),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
