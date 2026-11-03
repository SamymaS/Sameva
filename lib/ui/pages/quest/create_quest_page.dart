import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/create_quest_view_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pixel/pixel_ui.dart';
import '../../utils/app_notification.dart';

/// Création de quête — formulaire complet avec validation temps réel.
class CreateQuestPage extends StatefulWidget {
  /// Quête à modifier — null pour la création.
  final Quest? initialQuest;

  const CreateQuestPage({super.key, this.initialQuest});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  CreateQuestViewModel? _vm;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'Maison';
  ValidationType _validationType = ValidationType.manual;
  int _durationMinutes = 30;
  int _difficulty = 1;
  QuestFrequency _frequency = QuestFrequency.oneOff;
  String _scheduleOption = 'today';
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 23, minute: 59);

  bool get _isEditMode => widget.initialQuest != null;

  /// Sprint 1 : le serveur fige titre, catégorie, difficulté et mode de
  /// preuve 10 minutes après la création (code `champ_verrouille`).
  bool get _contentLocked =>
      _isEditMode &&
      DateTime.now().difference(widget.initialQuest!.createdAt) >=
          const Duration(minutes: 10);

  /// Une quête à preuve photo ne redevient jamais déclarative.
  bool get _proofRequiredInitially =>
      _isEditMode && widget.initialQuest!.validationType == ValidationType.photo;

  void _onValidationTypeChanged(ValidationType t) {
    final requiresProof = t == ValidationType.photo;
    if (_proofRequiredInitially && !requiresProof) {
      AppNotification.show(context,
          message: 'Une quête à preuve ne peut pas redevenir déclarative.');
      return;
    }
    setState(() => _validationType = t);
  }

  /// Rend un bloc non modifiable (grisé) quand le contenu est figé.
  Widget _lockable(Widget child) => _contentLocked
      ? Opacity(opacity: 0.45, child: AbsorbPointer(child: child))
      : child;
  bool get _canSubmit => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    final q = widget.initialQuest;
    if (q != null) {
      _titleController.text = q.title;
      _descriptionController.text = q.description ?? '';
      _category = q.category;
      _validationType = q.validationType;
      _durationMinutes = q.estimatedDurationMinutes;
      _difficulty = q.difficulty;
      _frequency = q.frequency;
      _scheduleOption = q.deadline != null ? 'today' : 'none';
      if (q.deadline != null) {
        _deadlineTime =
            TimeOfDay(hour: q.deadline!.hour, minute: q.deadline!.minute);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= CreateQuestViewModel(
      context.read<QuestViewModel>(),
      context.read<AuthViewModel>(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_vm == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = _vm!;
    return ChangeNotifierProvider<CreateQuestViewModel>.value(
      value: vm,
      child: Scaffold(
        backgroundColor: PixelCouleurs.nuit,
        appBar: AppBar(
          backgroundColor: PixelCouleurs.nuit,
          surfaceTintColor: Colors.transparent,
          foregroundColor: PixelCouleurs.texte,
          title: Text(
            _isEditMode ? 'Modifier la quête' : 'Nouvelle quête',
            style: PixelTextes.chiffres(13, PixelCouleurs.texte).copyWith(
              shadows: const [Shadow(color: PixelCouleurs.violet, offset: Offset(2, 2))],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Builder(
                builder: (ctx) {
                  final viewModel = ctx.watch<CreateQuestViewModel>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Titre ──────────────────────────────────────────
                      const _SectionLabel(label: 'Titre *'),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Titre de la quête',
                        child: TextFormField(
                          controller: _titleController,
                          enabled: !_contentLocked,
                          decoration: pixelChamp(exemple: 'Ex. Ranger ma chambre'),
                          style: PixelTextes.corps(17),
                          cursorColor: PixelCouleurs.violetClair,
                          maxLength: 80,
                          buildCounter: (_,
                                  {required currentLength,
                                  required isFocused,
                                  maxLength}) =>
                              Text('$currentLength/$maxLength',
                                  style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Indiquez un titre';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Description ────────────────────────────────────
                      const _SectionLabel(label: 'Description (optionnel)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: pixelChamp(exemple: 'Détails ou sous-objectifs…'),
                        style: PixelTextes.corps(17),
                        cursorColor: PixelCouleurs.violetClair,
                        maxLines: 3,
                        maxLength: 300,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            Text('$currentLength/$maxLength',
                                style: PixelTextes.corps(13, couleur: PixelCouleurs.texteDoux)),
                      ),
                      const SizedBox(height: 16),

                      // ── Catégorie ──────────────────────────────────────
                      const _SectionLabel(label: 'Catégorie'),
                      const SizedBox(height: 8),
                      _lockable(_CategoryPicker(
                        categories: vm.categories,
                        selected: _category,
                        onChanged: (c) => setState(() => _category = c),
                      )),
                      const SizedBox(height: 20),

                      // ── Difficulté ─────────────────────────────────────
                      const _SectionLabel(label: 'Difficulté'),
                      const SizedBox(height: 8),
                      _lockable(_DifficultyPicker(
                        value: _difficulty,
                        onChanged: (v) => setState(() => _difficulty = v),
                      )),
                      const SizedBox(height: 20),

                      // ── Type de validation ─────────────────────────────
                      const _SectionLabel(label: 'Validation'),
                      const SizedBox(height: 8),
                      _lockable(_ValidationTypePicker(
                        selected: _validationType,
                        onChanged: _onValidationTypeChanged,
                      )),
                      if (_contentLocked) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Titre, catégorie, difficulté et preuve sont figés '
                          '10 minutes après la création.',
                          style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ── Fréquence ──────────────────────────────────────
                      const _SectionLabel(label: 'Fréquence'),
                      const SizedBox(height: 8),
                      _FrequencyPicker(
                        selected: _frequency,
                        onChanged: (f) => setState(() => _frequency = f),
                      ),
                      const SizedBox(height: 20),

                      // ── Durée estimée ──────────────────────────────────
                      const _SectionLabel(label: 'Durée estimée'),
                      const SizedBox(height: 8),
                      _DurationPicker(
                        value: _durationMinutes,
                        onChanged: (v) => setState(() => _durationMinutes = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Échéance ───────────────────────────────────────
                      const _SectionLabel(label: 'Quand ?'),
                      const SizedBox(height: 8),
                      _SchedulePicker(
                        scheduleOption: _scheduleOption,
                        deadlineTime: _deadlineTime,
                        onScheduleChanged: (s) =>
                            setState(() => _scheduleOption = s),
                        onTimePick: () => _pickTime(context),
                      ),

                      // ── Erreur ─────────────────────────────────────────
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        PixelCadre(
                          bord: AppColors.error,
                          child: Text(viewModel.errorMessage!,
                              style: PixelTextes.corps(15, couleur: AppColors.error)),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ── Bouton créer ───────────────────────────────────
                      PixelBouton(
                        libelle: viewModel.isLoading
                            ? 'Enregistrement…'
                            : _isEditMode
                                ? 'Enregistrer les modifications'
                                : 'Créer la quête',
                        onPressed: (viewModel.isLoading || !_canSubmit) ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primaryTurquoise,
            surface: AppColors.backgroundDarkPanel,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadlineTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = _vm!;
    final now = DateTime.now();
    DateTime? deadline;
    switch (_scheduleOption) {
      case 'today':
        deadline = DateTime(now.year, now.month, now.day, _deadlineTime.hour,
            _deadlineTime.minute);
        break;
      case 'tomorrow':
        final t = now.add(const Duration(days: 1));
        deadline = DateTime(
            t.year, t.month, t.day, _deadlineTime.hour, _deadlineTime.minute);
        break;
      case 'week':
        final t = now.add(const Duration(days: 7));
        deadline = DateTime(
            t.year, t.month, t.day, _deadlineTime.hour, _deadlineTime.minute);
        break;
      case 'none':
      default:
        deadline = null;
    }
    bool ok;
    if (_isEditMode) {
      final q = widget.initialQuest!;
      final desc = _descriptionController.text.trim();
      final updated = Quest(
        id: q.id,
        userId: q.userId,
        title: _titleController.text.trim(),
        description: desc.isEmpty ? null : desc,
        estimatedDurationMinutes: _durationMinutes,
        frequency: _frequency,
        difficulty: _difficulty,
        category: _category,
        rarity: q.rarity,
        subQuests: q.subQuests,
        status: q.status,
        createdAt: q.createdAt,
        completedAt: q.completedAt,
        deadline: deadline,
        updatedAt: DateTime.now(),
        validationType: _validationType,
        xpReward: q.xpReward,
        goldReward: q.goldReward,
        proofData: q.proofData,
      );
      ok = await vm.updateQuest(updated);
    } else {
      ok = await vm.createQuest(
        title: _titleController.text.trim(),
        description: _descriptionController.text,
        category: _category,
        validationType: _validationType,
        durationMinutes: _durationMinutes,
        difficulty: _difficulty,
        frequency: _frequency,
        deadline: deadline,
      );
    }
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      if (!_isEditMode) Navigator.of(context).pop();
      AppNotification.show(context,
          message: _isEditMode ? 'Quête modifiée !' : 'Quête créée !');
    }
  }
}

// ── Widgets internes (style pixel) ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(label, style: PixelTextes.chiffres(10, PixelCouleurs.violetClair)),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in categories) PixelChoix(libelle: c, choisi: c == selected, onTap: () => onChanged(c)),
      ],
    );
  }
}

/// Difficulté : quatre blocs or qui se remplissent (1 à 4).
class _DifficultyPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DifficultyPicker({required this.value, required this.onChanged});

  static const _labels = ['Trivial', 'Facile', 'Normal', 'Difficile'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Semantics(
            container: true,
            button: true,
            selected: i + 1 == value,
            label: 'Difficulté ${i + 1} : ${_labels[i]}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(i + 1),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: i < value ? PixelCouleurs.or : PixelCouleurs.panneau,
                    border: Border(
                      top: BorderSide(color: i < value ? PixelCouleurs.orClair : PixelCouleurs.trait, width: 3),
                      left: BorderSide(color: i < value ? PixelCouleurs.orClair : PixelCouleurs.trait, width: 3),
                      right: BorderSide(color: i < value ? PixelCouleurs.orClair : PixelCouleurs.trait, width: 3),
                      bottom: BorderSide(color: i < value ? PixelCouleurs.orSombre : PixelCouleurs.trait, width: 6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: PixelTextes.chiffres(11, i < value ? PixelCouleurs.nuit : PixelCouleurs.texteDoux)),
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text(_labels[value - 1], style: PixelTextes.corps(16, couleur: PixelCouleurs.orClair, poids: FontWeight.w700)),
      ],
    );
  }
}

class _ValidationTypePicker extends StatelessWidget {
  final ValidationType selected;
  final ValueChanged<ValidationType> onChanged;

  const _ValidationTypePicker({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (type: ValidationType.manual, icon: Icons.check_box_outlined, label: 'Déclarative', accent: PixelCouleurs.violet),
    (type: ValidationType.photo, icon: Icons.photo_camera_outlined, label: 'Photo', accent: Color(0xFF0B6E9E)),
    (type: ValidationType.timer, icon: Icons.timer_outlined, label: 'Minuteur', accent: Color(0xFFB45309)),
    (type: ValidationType.geolocation, icon: Icons.place_outlined, label: 'Lieu', accent: Color(0xFF15803D)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opt in _options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == _options.last ? 0 : 8),
              child: PixelChoix(
                libelle: opt.label,
                icone: opt.icon,
                accent: opt.accent,
                vertical: true,
                choisi: opt.type == selected,
                onTap: () => onChanged(opt.type),
              ),
            ),
          ),
      ],
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  final QuestFrequency selected;
  final ValueChanged<QuestFrequency> onChanged;

  const _FrequencyPicker({required this.selected, required this.onChanged});

  static const _options = [
    (freq: QuestFrequency.oneOff, label: 'Unique'),
    (freq: QuestFrequency.daily, label: 'Quotidien'),
    (freq: QuestFrequency.weekly, label: 'Hebdo'),
    (freq: QuestFrequency.monthly, label: 'Mensuel'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opt in _options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == _options.last ? 0 : 8),
              child: PixelChoix(
                libelle: opt.label,
                choisi: opt.freq == selected,
                onTap: () => onChanged(opt.freq),
              ),
            ),
          ),
      ],
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  static const _options = [5, 10, 15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final minutes = _options[i];
          final label = minutes >= 60
              ? '${minutes ~/ 60} h${minutes % 60 > 0 ? " ${minutes % 60}" : ""}'
              : '$minutes min';
          return PixelChoix(libelle: label, choisi: minutes == value, onTap: () => onChanged(minutes));
        },
      ),
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  final String scheduleOption;
  final TimeOfDay deadlineTime;
  final ValueChanged<String> onScheduleChanged;
  final VoidCallback onTimePick;

  const _SchedulePicker({
    required this.scheduleOption,
    required this.deadlineTime,
    required this.onScheduleChanged,
    required this.onTimePick,
  });

  static const _scheduleOptions = [
    (value: 'today', label: "Aujourd'hui"),
    (value: 'tomorrow', label: 'Demain'),
    (value: 'week', label: '7 jours'),
    (value: 'none', label: 'Plus tard'),
  ];

  @override
  Widget build(BuildContext context) {
    final heure =
        '${deadlineTime.hour.toString().padLeft(2, '0')}:${deadlineTime.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in _scheduleOptions)
              PixelChoix(
                libelle: opt.label,
                choisi: opt.value == scheduleOption,
                onTap: () => onScheduleChanged(opt.value),
              ),
          ],
        ),
        // Le sélecteur d'heure n'apparaît que si une date est choisie.
        if (scheduleOption != 'none') ...[
          const SizedBox(height: 12),
          Semantics(
            container: true,
            button: true,
            label: 'Heure limite $heure, modifier',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTimePick,
              behavior: HitTestBehavior.opaque,
              child: PixelCadre(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: PixelCouleurs.texteDoux, size: 18),
                    const SizedBox(width: 10),
                    Text('Heure limite', style: PixelTextes.corps(16, couleur: PixelCouleurs.texteDoux)),
                    const SizedBox(width: 16),
                    Text(heure, style: PixelTextes.chiffres(12, PixelCouleurs.orClair)),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, color: PixelCouleurs.orClair, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
