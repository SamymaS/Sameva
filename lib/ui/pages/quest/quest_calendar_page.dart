import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/quest_detail_sheet.dart';

/// Vue calendrier hebdomadaire des quêtes.
/// Chaque colonne = un jour de la semaine courante.
/// Les quêtes actives avec deadline ce jour-là et les quêtes complétées ce jour-là y apparaissent.
class QuestCalendarPage extends StatefulWidget {
  const QuestCalendarPage({super.key});

  @override
  State<QuestCalendarPage> createState() => _QuestCalendarPageState();
}

class _QuestCalendarPageState extends State<QuestCalendarPage> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _prevWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() => setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  bool _isCurrent() {
    final now = _mondayOf(DateTime.now());
    return _weekStart == now;
  }

  @override
  Widget build(BuildContext context) {
    final quests = context.watch<QuestViewModel>().quests;
    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: AppColors.backgroundNightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundNightBlue,
        title: const Text(
          'Calendrier',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            onPressed: _prevWeek,
          ),
          Center(
            child: Text(
              _isCurrent() ? 'Cette semaine' : _weekLabel(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onPressed: _nextWeek,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: weekDays.map((day) {
          final dayQuests = _questsForDay(quests, day);
          return _DayColumn(day: day, quests: dayQuests);
        }).toList(),
      ),
    );
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_weekStart.day}/${_weekStart.month} – ${end.day}/${end.month}';
  }

  List<_DayQuest> _questsForDay(List<Quest> quests, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final result = <_DayQuest>[];

    for (final q in quests) {
      if (q.status == QuestStatus.active &&
          q.deadline != null &&
          !q.deadline!.isBefore(dayStart) &&
          q.deadline!.isBefore(dayEnd)) {
        result.add(_DayQuest(quest: q, kind: _QuestKind.deadline));
      } else if (q.status == QuestStatus.completed &&
          q.completedAt != null &&
          !q.completedAt!.isBefore(dayStart) &&
          q.completedAt!.isBefore(dayEnd)) {
        result.add(_DayQuest(quest: q, kind: _QuestKind.completed));
      }
    }

    return result;
  }
}

enum _QuestKind { deadline, completed }

class _DayQuest {
  final Quest quest;
  final _QuestKind kind;
  const _DayQuest({required this.quest, required this.kind});
}

class _DayColumn extends StatelessWidget {
  final DateTime day;
  final List<_DayQuest> quests;

  const _DayColumn({required this.day, required this.quests});

  static const _dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayNames[day.weekday - 1];
    final dateLabel = '${day.day}/${day.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isToday
              ? AppColors.primaryTurquoise.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.15),
          width: _isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du jour
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isToday
                        ? AppColors.primaryTurquoise.withValues(alpha: 0.15)
                        : AppColors.backgroundNightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      color: _isToday
                          ? AppColors.primaryTurquoise
                          : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                const Spacer(),
                if (quests.isNotEmpty)
                  Text(
                    '${quests.length} quête${quests.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
              ],
            ),
          ),

          // Liste des quêtes ou vide
          if (quests.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                'Aucune quête',
                style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            )
          else
            ...quests.map((dq) => _QuestTile(dq: dq)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final _DayQuest dq;

  const _QuestTile({required this.dq});

  Color _rarityColor(QuestRarity r) => switch (r) {
        QuestRarity.common => AppColors.rarityCommon,
        QuestRarity.uncommon => AppColors.rarityUncommon,
        QuestRarity.rare => AppColors.rarityRare,
        QuestRarity.epic => AppColors.rarityEpic,
        QuestRarity.legendary => AppColors.rarityLegendary,
        QuestRarity.mythic => AppColors.rarityMythic,
      };

  @override
  Widget build(BuildContext context) {
    final q = dq.quest;
    final color = _rarityColor(q.rarity);
    final isCompleted = dq.kind == _QuestKind.completed;

    return InkWell(
      onTap: () => QuestDetailSheet.show(context, quest: q),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isCompleted) ...[
                        const Icon(Icons.check_circle,
                            size: 10, color: AppColors.success),
                        const SizedBox(width: 3),
                        const Text('Terminée',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 10)),
                      ] else if (q.deadline != null) ...[
                        const Icon(Icons.schedule,
                            size: 10, color: AppColors.coralRare),
                        const SizedBox(width: 3),
                        Text(
                          _timeLabel(q.deadline!),
                          style: const TextStyle(
                              color: AppColors.coralRare, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'diff. ${q.difficulty}',
                style: TextStyle(color: color, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
