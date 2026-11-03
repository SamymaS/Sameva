import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/quest_model.dart';
import '../../../presentation/view_models/quest_view_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/quest_detail_sheet.dart';
import '../../widgets/pixel/pixel_ui.dart';

/// Vue calendrier hebdomadaire des quêtes (style pixel).
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
    final libelleSemaine = _isCurrent() ? 'Cette semaine' : _weekLabel();

    return Scaffold(
      backgroundColor: PixelCouleurs.nuit,
      appBar: pixelBarre('Calendrier'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Navigation de semaine : flèches carrées et libellé centré.
          Row(
            children: [
              _BoutonFleche(icone: Icons.chevron_left, libelle: 'Semaine précédente', onTap: _prevWeek),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(libelleSemaine,
                      textAlign: TextAlign.center, style: PixelTextes.chiffres(11, PixelCouleurs.orClair)),
                ),
              ),
              _BoutonFleche(icone: Icons.chevron_right, libelle: 'Semaine suivante', onTap: _nextWeek),
            ],
          ),
          const SizedBox(height: 14),
          for (final day in weekDays) _DayColumn(day: day, quests: _questsForDay(quests, day)),
        ],
      ),
    );
  }

  String _weekLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_weekStart.day}/${_weekStart.month} au ${end.day}/${end.month}';
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

class _BoutonFleche extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  const _BoutonFleche({required this.icone, required this.libelle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: libelle,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PixelCouleurs.panneau,
            border: Border(
              top: BorderSide(color: PixelCouleurs.violet, width: 3),
              left: BorderSide(color: PixelCouleurs.violet, width: 3),
              right: BorderSide(color: PixelCouleurs.violet, width: 3),
              bottom: BorderSide(color: PixelCouleurs.violetSombre, width: 6),
            ),
          ),
          child: Icon(icone, color: PixelCouleurs.texte),
        ),
      ),
    );
  }
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PixelCadre(
        bord: _isToday ? PixelCouleurs.or : PixelCouleurs.trait,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête du jour
            Semantics(
              header: true,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    color: _isToday ? PixelCouleurs.or : PixelCouleurs.panneauProfond,
                    child: Text(dayLabel,
                        style: PixelTextes.chiffres(9, _isToday ? PixelCouleurs.nuit : PixelCouleurs.texteDoux)),
                  ),
                  const SizedBox(width: 10),
                  Text(dateLabel, style: PixelTextes.chiffres(9, PixelCouleurs.texteDoux)),
                  if (_isToday) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text("Aujourd'hui",
                          overflow: TextOverflow.ellipsis,
                          style: PixelTextes.corps(14, couleur: PixelCouleurs.orClair, poids: FontWeight.w700)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: quests.isEmpty
                        ? const SizedBox.shrink()
                        : Text('${quests.length} quête${quests.length > 1 ? 's' : ''}',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: PixelTextes.corps(14, couleur: PixelCouleurs.texteDoux)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (quests.isEmpty)
              Text('Aucune quête', style: PixelTextes.corps(14, couleur: PixelCouleurs.trait))
            else
              for (final dq in quests) _QuestTile(dq: dq),
          ],
        ),
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
    final isCompleted = dq.kind == _QuestKind.completed;
    final couleur = isCompleted ? const Color(0xFF4ADE80) : _rarityColor(q.rarity);
    final d = q.difficulty.clamp(1, 4);

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: () => QuestDetailSheet.show(context, quest: q),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: PixelCouleurs.panneauProfond,
                border: Border(left: BorderSide(color: couleur, width: 4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PixelTextes.corps(16,
                                  couleur: isCompleted ? PixelCouleurs.texteDoux : PixelCouleurs.texte,
                                  poids: FontWeight.w700)
                              .copyWith(decoration: isCompleted ? TextDecoration.lineThrough : null),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (isCompleted) ...[
                              Icon(Icons.check, size: 14, color: couleur),
                              const SizedBox(width: 4),
                              Text('Terminée', style: PixelTextes.corps(14, couleur: couleur)),
                            ] else if (q.deadline != null) ...[
                              const Icon(Icons.schedule, size: 14, color: Color(0xFFFCA5A5)),
                              const SizedBox(width: 4),
                              Text('Avant ${_timeLabel(q.deadline!)}',
                                  style: PixelTextes.corps(14, couleur: const Color(0xFFFCA5A5))),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Difficulté $d sur 4',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 4; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 2),
                            color: i < d ? PixelCouleurs.or : PixelCouleurs.trait,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
