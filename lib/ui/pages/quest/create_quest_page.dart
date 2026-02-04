import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/quest_provider.dart';
import '../../../presentation/view_models/create_quest_view_model.dart';
import '../../theme/app_colors.dart';

/// Création de quête — MVVM, Hick (champs essentiels), Jakob (formulaire standard).
/// Fitts : bouton Valider large.
class CreateQuestPage extends StatefulWidget {
  const CreateQuestPage({super.key});

  @override
  State<CreateQuestPage> createState() => _CreateQuestPageState();
}

class _CreateQuestPageState extends State<CreateQuestPage> {
  CreateQuestViewModel? _vm;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _category = 'Maison';
  ValidationType _validationType = ValidationType.manual;
  int _durationMinutes = 30;
  String _scheduleOption = 'today'; // planification simple

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm ??= CreateQuestViewModel(
      context.read<QuestProvider>(),
      context.read<AuthProvider>(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
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
        appBar: AppBar(
          title: const Text('Nouvelle quête'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Builder(
                builder: (ctx) {
                  final viewModel = ctx.watch<CreateQuestViewModel>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre de la quête',
                          hintText: 'Ex. Ranger ma chambre',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Indiquez un titre';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        items: vm.categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: 24),
                      const Text('Type de validation', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SegmentedButton<ValidationType>(
                        segments: const [
                          ButtonSegment(
                            value: ValidationType.manual,
                            label: Text('Simple'),
                            icon: Icon(Icons.check_box_outlined),
                          ),
                          ButtonSegment(
                            value: ValidationType.photo,
                            label: Text('Photo'),
                            icon: Icon(Icons.camera_alt_outlined),
                          ),
                        ],
                        selected: {_validationType},
                        onSelectionChanged: (s) => setState(() => _validationType = s.first),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: _durationMinutes,
                        decoration: const InputDecoration(labelText: 'Durée estimée (min)'),
                        items: [15, 30, 45, 60, 90]
                            .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                            .toList(),
                        onChanged: (v) => setState(() => _durationMinutes = v ?? 30),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _scheduleOption,
                        decoration: const InputDecoration(labelText: 'Quand ?'),
                        items: const [
                          DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
                          DropdownMenuItem(value: 'tomorrow', child: Text('Demain')),
                          DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
                          DropdownMenuItem(value: 'none', child: Text('Plus tard')),
                        ],
                        onChanged: (v) => setState(() => _scheduleOption = v ?? 'today'),
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: AppColors.error, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: viewModel.isLoading ? null : _submit,
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Créer la quête'),
                      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = _vm!;
    final now = DateTime.now();
    DateTime? deadline;
    switch (_scheduleOption) {
      case 'today':
        deadline = DateTime(now.year, now.month, now.day, 23, 59);
        break;
      case 'tomorrow':
        final t = now.add(const Duration(days: 1));
        deadline = DateTime(t.year, t.month, t.day, 23, 59);
        break;
      case 'week':
        final t = now.add(const Duration(days: 7));
        deadline = DateTime(t.year, t.month, t.day, 23, 59);
        break;
      case 'none':
      default:
        deadline = null;
        break;
    }
    final ok = await vm.createQuest(
      title: _titleController.text.trim(),
      category: _category,
      validationType: _validationType,
      durationMinutes: _durationMinutes,
      deadline: deadline,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(); // ferme formulaire
      Navigator.of(context).pop(); // ferme page de choix → retour à la liste
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quête créée')),
      );
    }
  }
}
