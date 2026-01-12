import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/providers/auth_provider.dart';
import '../../core/providers/quest_provider.dart';
import '../../widgets/fantasy/fantasy_button.dart';
import '../../widgets/fantasy/fantasy_card.dart';
import '../../widgets/fantasy/fantasy_text_field.dart';

class FantasyCreateQuestPage extends StatefulWidget {
  const FantasyCreateQuestPage({super.key});

  @override
  State<FantasyCreateQuestPage> createState() => _FantasyCreateQuestPageState();
}

class _FantasyCreateQuestPageState extends State<FantasyCreateQuestPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  QuestFrequency _frequency = QuestFrequency.once;
  int _difficulty = 1;
  String _category = 'Quotidienne';
  List<String> _subQuests = [];
  bool _isLoading = false;

  late AnimationController _backgroundController;
  late AnimationController _particleController;

  final List<String> _categories = [
    'Quotidienne',
    'Hebdomadaire',
    'Mensuelle',
    'Spéciale',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _addSubQuest() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        final controller = TextEditingController();
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FantasyCard(
            glowColor: const Color(0xFF1AA7EC),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajouter une sous-quête',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                FantasyTextField(
                  hint: 'Titre de la sous-quête',
                  controller: controller,
                  glowColor: const Color(0xFF1AA7EC),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FantasyButton(
                      label: 'Ajouter',
                      glowColor: const Color(0xFF1AA7EC),
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() {
                            _subQuests.add(controller.text.trim());
                          });
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  QuestRarity _calculateRarity() {
    final score = _difficulty + (_subQuests.length / 2).round();
    if (score <= 2) return QuestRarity.common;
    if (score <= 4) return QuestRarity.uncommon;
    if (score <= 6) return QuestRarity.rare;
    if (score <= 8) return QuestRarity.veryRare;
    if (score <= 10) return QuestRarity.epic;
    if (score <= 12) return QuestRarity.legendary;
    return QuestRarity.mythic;
  }

  Color _getRarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return const Color(0xFF9CA3AF);
      case QuestRarity.uncommon:
        return const Color(0xFF22C55E);
      case QuestRarity.rare:
        return const Color(0xFF60A5FA);
      case QuestRarity.veryRare:
        return const Color(0xFFA855F7);
      case QuestRarity.epic:
        return const Color(0xFFF59E0B);
      case QuestRarity.legendary:
        return const Color(0xFFFFD700);
      case QuestRarity.mythic:
        return const Color(0xFFEF4444);
    }
  }

  Future<void> _createQuest() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un titre'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthProvider>().user?.uid ?? '';
      final rarity = _calculateRarity();

      final quest = Quest(
        title: _titleController.text,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        estimatedDuration: Duration(minutes: 30 * _difficulty),
        frequency: _frequency,
        difficulty: _difficulty,
        category: _category,
        rarity: rarity,
        subQuests: _subQuests,
      );

      await context.read<QuestProvider>().addQuest(userId, quest);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: _getRarityColor(rarity)),
                const SizedBox(width: 8),
                Text('Quête ${rarity.toString().split('.').last} créée !'),
              ],
            ),
            backgroundColor: _getRarityColor(rarity).withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarity = _calculateRarity();
    final rarityColor = _getRarityColor(rarity);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F18),
      body: Stack(
        children: [
          // Fond animé avec gradient
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.cos(_backgroundController.value * 2 * math.pi) * 0.3,
                      math.sin(_backgroundController.value * 2 * math.pi) * 0.3,
                    ),
                    radius: 1.5,
                    colors: [
                      const Color(0xFF1AA7EC).withOpacity(0.1),
                      const Color(0xFF0B0F18),
                    ],
                  ),
                ),
              );
            },
          ),
          // Particules flottantes
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FloatingParticlesPainter(_particleController.value),
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header avec titre stylisé
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Nouvelle Quête',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Aperçu de la rareté
                  FantasyCard(
                    glowColor: rarityColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: rarityColor),
                        const SizedBox(width: 8),
                        Text(
                          'Rareté: ${rarity.toString().split('.').last.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rarityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Titre
                  FantasyTextField(
                    label: 'Titre de la quête',
                    hint: 'Ex: Méditer 10 minutes',
                    controller: _titleController,
                    glowColor: const Color(0xFF1AA7EC),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  FantasyTextField(
                    label: 'Description',
                    hint: 'Décris ta quête en détail...',
                    controller: _descriptionController,
                    maxLines: 4,
                    glowColor: const Color(0xFF1AA7EC),
                  ),
                  const SizedBox(height: 16),
                  // Catégorie
                  FantasyCard(
                    glowColor: const Color(0xFF60A5FA),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catégorie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = _category == cat;
                            return GestureDetector(
                              onTap: () => setState(() => _category = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF60A5FA).withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF60A5FA).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Difficulté
                  FantasyCard(
                    glowColor: const Color(0xFFF59E0B),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Difficulté',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  Icons.star,
                                  size: 24,
                                  color: index < _difficulty
                                      ? const Color(0xFFF59E0B)
                                      : Colors.white24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: _difficulty.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: const Color(0xFFF59E0B),
                          inactiveColor: const Color(0xFF1B2336),
                          onChanged: (value) => setState(() => _difficulty = value.round()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fréquence
                  FantasyCard(
                    glowColor: const Color(0xFFA855F7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fréquence',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButton<QuestFrequency>(
                          value: _frequency,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0E1422),
                          style: const TextStyle(color: Colors.white),
                          items: QuestFrequency.values.map((freq) {
                            return DropdownMenuItem(
                              value: freq,
                              child: Text(freq.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _frequency = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sous-quêtes
                  FantasyButton(
                    label: 'Ajouter une sous-quête',
                    icon: Icons.add,
                    glowColor: const Color(0xFF1AA7EC),
                    onPressed: _addSubQuest,
                    width: double.infinity,
                  ),
                  if (_subQuests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FantasyCard(
                      glowColor: const Color(0xFF22C55E),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sous-quêtes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            _subQuests.length,
                            (index) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2336),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF22C55E).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF22C55E),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _subQuests[index],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _subQuests.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Bouton de création
                  FantasyButton(
                    label: _isLoading ? 'Création en cours...' : 'CRÉER LA QUÊTE',
                    icon: Icons.auto_awesome,
                    glowColor: rarityColor,
                    onPressed: _isLoading ? null : _createQuest,
                    width: double.infinity,
                    pulsing: !_isLoading,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  _FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Seed fixe pour la cohérence

    for (int i = 0; i < 20; i++) {
      final x = (random.nextDouble() * size.width + animationValue * 100) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 50) % size.height;
      final opacity = (math.sin(animationValue * 2 * math.pi + i) * 0.3 + 0.4).clamp(0.0, 1.0);
      final size_particle = 2 + random.nextDouble() * 3;

      final paint = Paint()
        ..color = const Color(0xFF1AA7EC).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), size_particle, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter oldDelegate) => true;
}

