import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../core/providers/quest_provider.dart';
import '../../core/providers/auth_provider.dart';

class QuestDetailPage extends StatefulWidget {
  final Quest quest;
  const QuestDetailPage({super.key, required this.quest});

  @override
  State<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends State<QuestDetailPage> {
  late List<bool> _localSubCompleted;

  @override
  void initState() {
    super.initState();
    _localSubCompleted = List<bool>.filled(widget.quest.subQuests.length, false);
  }

  Color _rarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common: return AppColors.common;
      case QuestRarity.uncommon: return AppColors.uncommon;
      case QuestRarity.rare: return AppColors.rare;
      case QuestRarity.veryRare: return AppColors.veryRare;
      case QuestRarity.epic: return AppColors.epic;
      case QuestRarity.legendary: return AppColors.legendary;
      case QuestRarity.mythic: return AppColors.mythic;
    }
  }

  Future<void> _completeQuest() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    await context.read<QuestProvider>().completeQuest(userId, widget.quest.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quête terminée !')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(widget.quest.rarity);

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la quête')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [rarityColor.withOpacity(0.15), Colors.white]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: rarityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.quest.rarity.toString().split('.').last, style: TextStyle(color: rarityColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(widget.quest.frequency.toString().split('.').last, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.quest.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.quest.description != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.quest.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Durée estimée: ${widget.quest.estimatedDuration.inHours}h ${widget.quest.estimatedDuration.inMinutes % 60}min'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.quest.subQuests.isNotEmpty) ...[
            Text('Sous-quêtes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(widget.quest.subQuests.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  value: _localSubCompleted[i],
                  onChanged: (v) => setState(() => _localSubCompleted[i] = v ?? false),
                  title: Text(widget.quest.subQuests[i]),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _completeQuest,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terminer la quête'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
