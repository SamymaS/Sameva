import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/quest_model.dart';

/// Génère automatiquement un boss hebdomadaire chaque semaine.
/// Identifié par la clé Hive 'weekly_boss_week' (format: YYYY_WW).
class WeeklyBossService {
  static const _bossWeekKey = 'weekly_boss_week';

  static Box get _box => Hive.box('settings');

  static String _weekKey() {
    final now = DateTime.now();
    // Semaine ISO : nombre de jours depuis le lundi de la semaine courante
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}_${monday.month.toString().padLeft(2, '0')}_${monday.day.toString().padLeft(2, '0')}';
  }

  static bool hasGeneratedThisWeek() {
    return _box.get(_bossWeekKey) == _weekKey();
  }

  static Future<void> markGenerated() async {
    await _box.put(_bossWeekKey, _weekKey());
  }

  /// Retourne la quête boss à créer pour cette semaine.
  static Quest buildBossQuest(String userId) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59));

    final idx = now.weekNumber % _bosses.length;
    final boss = _bosses[idx];

    return Quest(
      userId: userId,
      title: '⚔️ Boss : ${boss.name}',
      description: boss.lore,
      estimatedDurationMinutes: 60,
      frequency: QuestFrequency.weekly,
      difficulty: 5,
      category: 'boss',
      rarity: QuestRarity.epic,
      status: QuestStatus.active,
      createdAt: monday,
      deadline: sunday,
      xpReward: boss.xp,
      goldReward: boss.gold,
    );
  }

  static const _bosses = [
    _Boss('Le Colosse de Fer',   'Une montagne de métal forgé par la haine. Seule la persévérance peut le briser.', 300, 200),
    _Boss('L\'Hydre des Brumes', 'Trois têtes, trois vérités difficiles. Chaque victoire en mène une nouvelle.', 280, 220),
    _Boss('Le Dragon Solaire',   'Enfant des étoiles tombées, il brûle tout ce qui n\'ose pas avancer.', 350, 180),
    _Boss('L\'Ombre Éternelle',  'Il se nourrit de l\'inaction. La seule arme contre lui : agir.', 260, 250),
    _Boss('Le Titan de Pierre',  'Immobile depuis des siècles, il cède devant la constance.', 320, 190),
    _Boss('La Reine des Abysses','Venue des profondeurs, elle tente de ramener le joueur vers ses anciennes habitudes.', 290, 210),
    _Boss('Le Phénix Noir',      'Renaît de ses cendres à chaque abandon. Seule une victoire définitive compte.', 370, 160),
    _Boss('Le Gardien du Temps', 'Il ralentit tout. La procrastination faite entité.', 240, 270),
  ];
}

class _Boss {
  final String name;
  final String lore;
  final int xp;
  final int gold;

  const _Boss(this.name, this.lore, this.xp, this.gold);
}

extension on DateTime {
  int get weekNumber {
    final dayOfYear = difference(DateTime(year, 1, 1)).inDays + 1;
    return ((dayOfYear - weekday + 10) / 7).floor();
  }
}
