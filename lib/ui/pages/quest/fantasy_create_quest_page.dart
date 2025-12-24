import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

// Importe tes nouveaux modèles DATA (Supabase)
import '../../../data/models/quest_model.dart';
// Importe ton Provider DATA
import '../../../presentation/providers/quest_provider.dart';

// Importe tes widgets UI existants (Design System)
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

  // --- VARIABLES D'ÉTAT (Compatibles Supabase) ---
  QuestFrequency _frequency = QuestFrequency.oneOff;
  int _difficulty = 1;
  String _category = 'Maison'; // Valeur par défaut
  List<String> _subQuests = [];
  bool _isLoading = false;
  
  // NOUVEAU : Anti-triche (Phase 2)
  bool _isPhotoValidation = false;

  late AnimationController _backgroundController;
  late AnimationController _particleController;

  // Catégories (UI String -> Sera stocké en String dans la DB)
  final List<String> _categories = [
    'Maison', 'Sport', 'Santé', 'Études', 'Créatif'
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

  // --- LOGIQUE METIER (Calculs) ---

  // Calcul dynamique de la rareté basé sur la difficulté + anti-triche
  QuestRarity _calculateRarity() {
    int score = _difficulty;
    if (_isPhotoValidation) score += 2; // Bonus rareté si anti-triche activé !
    if (_subQuests.isNotEmpty) score += 1;

    if (score <= 1) return QuestRarity.common;
    if (score <= 2) return QuestRarity.uncommon;
    if (score <= 3) return QuestRarity.rare;
    if (score <= 4) return QuestRarity.epic;
    if (score <= 5) return QuestRarity.legendary;
    return QuestRarity.mythic;
  }
  
  // Calcul des récompenses (Affichage uniquement)
  int get _estimatedXp => (_difficulty * 10) + (_isPhotoValidation ? 20 : 0);
  int get _estimatedGold => (_difficulty * 5);

  Color _getRarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common: return const Color(0xFF9CA3AF);
      case QuestRarity.uncommon: return const Color(0xFF22C55E);
      case QuestRarity.rare: return const Color(0xFF60A5FA);
      case QuestRarity.epic: return const Color(0xFFA855F7);
      case QuestRarity.legendary: return const Color(0xFFF59E0B);
      case QuestRarity.mythic: return const Color(0xFFFFD700);
    }
  }

  // --- SOUMISSION DU FORMULAIRE (Connecté à Supabase) ---
  Future<void> _createQuest() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le pacte nécessite un titre...'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Récupérer l'User ID directement depuis Supabase (Plus fiable)
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Âme non identifiée (Non connecté)");

      final rarity = _calculateRarity();

      // 2. Créer l'objet Quest avec le NOUVEAU Modèle
      final quest = Quest(
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        
        // Mapping des valeurs UI -> Modèle
        category: _category,
        difficulty: _difficulty,
        frequency: _frequency,
        rarity: rarity,
        
        // Nouveaux champs Phase 2 & MVP
        validationType: _isPhotoValidation ? ValidationType.photo : ValidationType.manual,
        xpReward: _estimatedXp,
        goldReward: _estimatedGold,
        estimatedDurationMinutes: 30 * _difficulty, // Estimation simple pour MVP
        
        status: QuestStatus.active,
      );

      // 3. Envoyer via le Provider
      await context.read<QuestProvider>().addQuest(quest);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome, color: _getRarityColor(rarity)),
                const SizedBox(width: 10),
                Text('Pacte scellé ! (+${_estimatedXp} XP promis)'),
              ],
            ),
            backgroundColor: const Color(0xFF1B2336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur du rituel : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // --- HELPERS UI (Ta méthode restaurée) ---
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

  @override
  Widget build(BuildContext context) {
    final rarity = _calculateRarity();
    final rarityColor = _getRarityColor(rarity);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F18),
      body: Stack(
        children: [
          // 1. FOND ANIMÉ
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
                    colors: [const Color(0xFF1AA7EC).withOpacity(0.1), const Color(0xFF0B0F18)],
                  ),
                ),
              );
            },
          ),
          
          // 2. PARTICULES
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FloatingParticlesPainter(_particleController.value)),
            ),
          ),

          // 3. CONTENU SCROLLABLE
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // HEADER (Retour + Titre)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Nouveau Pacte',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cinzel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Pour équilibrer le titre
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CARTE APERÇU RARETÉ (Dynamique)
                  FantasyCard(
                    glowColor: rarityColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield, color: rarityColor),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rareté : ${rarity.name.toUpperCase()}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: rarityColor),
                            ),
                            Text(
                              'Récompense : $_estimatedXp XP | $_estimatedGold Or',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CHAMPS TEXTE
                  FantasyTextField(
                    label: 'Titre de la quête',
                    hint: 'Ex: Vaincre le boss (Faire la vaisselle)',
                    controller: _titleController,
                    glowColor: const Color(0xFF1AA7EC),
                  ),
                  const SizedBox(height: 16),
                  
                  FantasyTextField(
                    label: 'Description (Optionnel)',
                    hint: 'Détails du contrat...',
                    controller: _descriptionController,
                    maxLines: 3,
                    glowColor: const Color(0xFF1AA7EC),
                  ),
                  const SizedBox(height: 24),

                  // SÉLECTEUR CATÉGORIE
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _category == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF60A5FA).withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF60A5FA) : Colors.white24,
                              ),
                            ),
                            child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SLIDER DIFFICULTÉ
                  Text("Niveau de difficulté : $_difficulty", style: const TextStyle(color: Colors.white70)),
                  Slider(
                    value: _difficulty.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (val) => setState(() => _difficulty = val.round()),
                  ),

                  // NOUVEAU : SWITCH ANTI-TRICHE (Phase 2)
                  FantasyCard(
                    glowColor: _isPhotoValidation ? Colors.amber : Colors.grey.withOpacity(0.3),
                    child: SwitchListTile(
                      title: const Text("Preuve Visuelle Requise ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text("Prouve ta valeur à l'Oracle.\nBonus : +20 XP", style: TextStyle(color: Colors.white60, fontSize: 12)),
                      value: _isPhotoValidation,
                      activeColor: Colors.amber,
                      secondary: const Icon(Icons.camera_alt, color: Colors.white),
                      onChanged: (val) => setState(() => _isPhotoValidation = val),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // SECTION SOUS-QUÊTES
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
                  const SizedBox(height: 30),

                  // BOUTON CRÉATION
                  FantasyButton(
                    label: _isLoading ? 'Invocation...' : 'SCELLER LE PACTE',
                    icon: Icons.auto_awesome,
                    glowColor: rarityColor,
                    onPressed: _isLoading ? null : _createQuest,
                    width: double.infinity,
                    pulsing: !_isLoading,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PAINTER POUR LES PARTICULES
class _FloatingParticlesPainter extends CustomPainter {
  final double animationValue;
  _FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
     final random = math.Random(42); 
    for (int i = 0; i < 20; i++) {
      final x = (random.nextDouble() * size.width + animationValue * 100) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 50) % size.height;
      final opacity = (math.sin(animationValue * 2 * math.pi + i) * 0.3 + 0.4).clamp(0.0, 1.0);
      final size_particle = 2 + random.nextDouble() * 3;
      final paint = Paint()..color = const Color(0xFF1AA7EC).withOpacity(opacity)..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), size_particle, paint);
    }
  }
  @override
  bool shouldRepaint(_FloatingParticlesPainter oldDelegate) => true;
}
