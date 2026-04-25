import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service de régénération HP.
///
/// Logique :
/// - Chaque heure complète depuis la dernière connexion → +10% du maxHP
/// - Plafonné à maxHP, maximum 8 heures de regen (nuit de sommeil)
/// - Appliqué une seule fois par session (à l'ouverture de l'app)
///
/// Usage dans PlayerProvider.loadPlayerStats :
/// ```dart
/// final regenHp = HealthRegenerationService.computeRegen(
///   currentHp: stats.healthPoints,
///   maxHp: stats.maxHealthPoints,
/// );
/// if (regenHp > 0) await heal(userId, regenHp);
/// ```
class HealthRegenerationService {
  static const String _lastRegenKey = 'last_hp_regen_at';
  static const double _regenPerHour = 0.10; // 10% du maxHP par heure
  static const int _maxRegenHours = 8;

  static Box get _box => Hive.box('settings');

  /// Calcule la quantité de HP à régénérer.
  /// Retourne 0 si moins d'une heure s'est écoulée ou si HP est déjà max.
  /// Met à jour l'horodatage interne après calcul.
  static int computeRegen({
    required int currentHp,
    required int maxHp,
  }) {
    if (currentHp >= maxHp) {
      _updateTimestamp();
      return 0;
    }

    try {
      final now = DateTime.now();
      final lastRegenRaw = _box.get(_lastRegenKey) as String?;

      if (lastRegenRaw == null) {
        _box.put(_lastRegenKey, now.toIso8601String());
        return 0;
      }

      final lastRegen = DateTime.parse(lastRegenRaw);
      final hoursElapsed = now.difference(lastRegen).inMinutes / 60.0;

      if (hoursElapsed < 1.0) return 0;

      final effectiveHours = hoursElapsed.clamp(0.0, _maxRegenHours.toDouble());
      final regenAmount = (maxHp * _regenPerHour * effectiveHours).round();

      _box.put(_lastRegenKey, now.toIso8601String());

      debugPrint(
        'HealthRegen: +$regenAmount HP '
        '(${effectiveHours.toStringAsFixed(1)}h × ${(_regenPerHour * 100).round()}%)',
      );
      return regenAmount;
    } catch (e) {
      debugPrint('HealthRegenerationService: erreur: $e');
      return 0;
    }
  }

  /// Preview sans modifier l'horodatage (pour affichage UI).
  static int previewRegen({required int maxHp}) {
    try {
      final lastRegenRaw = _box.get(_lastRegenKey) as String?;
      if (lastRegenRaw == null) return 0;
      final hoursElapsed =
          DateTime.now().difference(DateTime.parse(lastRegenRaw)).inMinutes /
              60.0;
      if (hoursElapsed < 1.0) return 0;
      final effectiveHours = hoursElapsed.clamp(0.0, _maxRegenHours.toDouble());
      return (maxHp * _regenPerHour * effectiveHours).round();
    } catch (_) {
      return 0;
    }
  }

  static void _updateTimestamp() {
    try {
      _box.put(_lastRegenKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('HealthRegen: erreur updateTimestamp: $e');
    }
  }
}
