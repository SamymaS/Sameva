import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../presentation/view_models/auth_view_model.dart';
import '../../../presentation/view_models/create_quest_view_model.dart';
import '../../theme/app_colors.dart';

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
      context.read<QuestRepository>(),
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
        backgroundColor: AppColors.backgroundNightBlue,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundNightBlue,
          title: Text(
            _isEditMode ? 'Modifier la quête' : 'Nouvelle quête',
            style: const TextStyle(
                color: AppColors.primaryTurquoise, fontWeight: FontWeight.bold),
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
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Ex. Ranger ma chambre',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.backgroundDarkPanel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTurquoise),
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                        maxLength: 80,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                            Text('$currentLength/$maxLength',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Indiquez un titre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Description ────────────────────────────────────
                      const _SectionLabel(label: 'Description (optionnel)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Détails ou sous-objectifs…',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.backgroundDarkPanel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.primaryTurquoise),
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                        maxLines: 3,
                        maxLength: 300,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                            Text('$currentLength/$maxLength',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                      ),
                      const SizedBox(height: 16),

                      // ── Catégorie ──────────────────────────────────────
                      const _SectionLabel(label: 'Catégorie'),
                      const SizedBox(height: 8),
                      _CategoryPicker(
                        categories: vm.categories,
                        selected: _category,
                        onChanged: (c) => setState(() => _category = c),
                      ),
                      const SizedBox(height: 20),

                      // ── Difficulté ─────────────────────────────────────
                      const _SectionLabel(label: 'Difficulté'),
                      const SizedBox(height: 8),
                      _DifficultyPicker(
                        value: _difficulty,
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Type de validation ─────────────────────────────
                      const _SectionLabel(label: 'Validation'),
                      const SizedBox(height: 8),
                      _ValidationTypePicker(
                        selected: _validationType,
                        onChanged: (t) =>
                            setState(() => _validationType = t),
                      ),
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
                        onChanged: (v) =>
                            setState(() => _durationMinutes = v),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // ── Bouton créer ───────────────────────────────────
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: (viewModel.isLoading || !_canSubmit)
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryTurquoise,
                            foregroundColor: AppColors.backgroundNightBlue,
                            disabledBackgroundColor:
                                AppColors.primaryTurquoise.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.backgroundNightBlue),
                                )
                              : const Text('Créer la quête'),
                        ),
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
        deadline = DateTime(now.year, now.month, now.day,
            _deadlineTime.hour, _deadlineTime.minute);
        break;
      case 'tomorrow':
        final t = now.add(const Duration(days: 1));
        deadline = DateTime(t.year, t.month, t.day,
            _deadlineTime.hour, _deadlineTime.minute);
        break;
      case 'week':
        final t = now.add(const Duration(days: 7));
        deadline = DateTime(t.year, t.month, t.day,
            _deadlineTime.hour, _deadlineTime.minute);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? 'Quête modifiée !' : 'Quête créée !')),
      );
    }
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
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
      children: categories.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                  : AppColors.backgroundDarkPanel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryTurquoise
                    : AppColors.inputBorder,
              ),
            ),
            child: Text(
              c,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryTurquoise
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DifficultyPicker({required this.value, required this.onChanged});

  static const _labels = ['Trivial', 'Facile', 'Normal', 'Difficile', 'Épique'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < value;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? AppColors.gold : AppColors.textMuted,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 10),
        Text(
          _labels[value - 1],
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
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
    (type: ValidationType.manual, icon: Icons.check_outlined, label: 'Manuel'),
    (type: ValidationType.photo, icon: Icons.camera_alt_outlined, label: 'Photo'),
    (type: ValidationType.ai, icon: Icons.psychology_outlined, label: 'IA texte'),
    (type: ValidationType.timer, icon: Icons.timer_outlined, label: 'Timer'),
    (type: ValidationType.geolocation, icon: Icons.location_on_outlined, label: 'Lieu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSelected = opt.type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.type),
            child: Container(
              margin: EdgeInsets.only(
                  right: opt == _options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                    : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTurquoise
                      : AppColors.inputBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(opt.icon,
                      size: 20,
                      color: isSelected
                          ? AppColors.primaryTurquoise
                          : AppColors.textMuted),
                  const SizedBox(height: 4),
                  Text(opt.label,
                      style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryTurquoise
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
      children: _options.map((opt) {
        final isSelected = opt.freq == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.freq),
            child: Container(
              margin: EdgeInsets.only(
                  right: opt == _options.last ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryViolet.withValues(alpha: 0.15)
                    : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondaryViolet
                      : AppColors.inputBorder,
                ),
              ),
              child: Center(
                child: Text(opt.label,
                    style: TextStyle(
                        color: isSelected
                            ? AppColors.secondaryVioletGlow
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal)),
              ),
            ),
          ),
        );
      }).toList(),
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final minutes = _options[i];
          final isSelected = minutes == value;
          final label = minutes >= 60
              ? '${minutes ~/ 60}h${minutes % 60 > 0 ? "${minutes % 60}m" : ""}'
              : '${minutes}m';
          return GestureDetector(
            onTap: () => onChanged(minutes),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                    : AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTurquoise
                      : AppColors.inputBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryTurquoise
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scheduleOptions.map((opt) {
            final isSelected = opt.value == scheduleOption;
            return GestureDetector(
              onTap: () => onScheduleChanged(opt.value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                      : AppColors.backgroundDarkPanel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryTurquoise
                        : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryTurquoise
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Afficher le sélecteur d'heure seulement si une date est choisie
        if (scheduleOption != 'none') ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTimePick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarkPanel,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time,
                      color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  const Text('Heure limite',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 16),
                  Text(
                    '${deadlineTime.hour.toString().padLeft(2, '0')}:${deadlineTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.primaryTurquoise,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined,
                      color: AppColors.primaryTurquoise, size: 14),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
