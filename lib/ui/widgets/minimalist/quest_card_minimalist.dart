import 'package:flutter/material.dart';
import '../../../data/models/quest_model.dart';
import '../../theme/app_colors.dart';
import '../magical/hover_scale.dart';

/// Carte de quête minimaliste pour le panneau glissant
/// Style "Moderne Éthérée" - Hauteur fixe 80px avec micro-interactions

class QuestCardMinimalist extends StatefulWidget {
  final Quest quest;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const QuestCardMinimalist({
    super.key,
    required this.quest,
    this.onTap,
    this.onComplete,
  });

  @override
  State<QuestCardMinimalist> createState() => _QuestCardMinimalistState();
}

class _QuestCardMinimalistState extends State<QuestCardMinimalist>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppColors.rarityUncommon; // Vert
      case 2:
        return AppColors.rarityRare; // Bleu
      case 3:
        return AppColors.rarityEpic; // Orange
      case 4:
      case 5:
        return AppColors.rarityMythic; // Rouge
      default:
        return AppColors.rarityCommon;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'maison':
        return Icons.home_outlined;
      case 'sport':
        return Icons.fitness_center_outlined;
      case 'santé':
        return Icons.favorite_outline;
      case 'études':
        return Icons.menu_book_outlined;
      case 'créatif':
        return Icons.palette_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(widget.quest.difficulty);
    final categoryIcon = _getCategoryIcon(widget.quest.category);

    return HoverScale(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_hoverController.value * 0.02), // Légère compression au tap
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                // Fond très sombre translucide avec transition
                color: _isHovered
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: difficultyColor,
                    width: 3,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icône de catégorie avec animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? difficultyColor.withOpacity(0.3)
                              : difficultyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          categoryIcon,
                          size: 18,
                          color: difficultyColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Titre
                            Text(
                              widget.quest.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Sous-titre (catégorie + récompense)
                            Row(
                              children: [
                                Text(
                                  widget.quest.category,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star_outline,
                                  size: 12,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+${widget.quest.xpReward ?? 0} XP',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Rune de validation (Checkbox) avec animation
                      GestureDetector(
                        onTap: widget.onComplete,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.quest.status == QuestStatus.completed
                                  ? AppColors.primaryTurquoise
                                  : Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            color: widget.quest.status == QuestStatus.completed
                                ? AppColors.primaryTurquoise.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: widget.quest.status == QuestStatus.completed
                              ? Icon(
                                  Icons.check,
                                  color: AppColors.primaryTurquoise,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

