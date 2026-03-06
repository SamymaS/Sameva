import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/services/notification_service.dart';

/// Provider minimal pour gérer l'heure du rappel quotidien de quêtes.
/// L'heure est persistée dans la boîte Hive 'settings'.
class NotificationProvider with ChangeNotifier {
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  Box get _box => Hive.box('settings');

  int get reminderHour => _box.get(_keyHour, defaultValue: 9) as int;
  int get reminderMinute => _box.get(_keyMinute, defaultValue: 0) as int;

  /// Retourne l'heure formatée pour l'affichage (ex: "09:00").
  String get reminderTimeLabel {
    final h = reminderHour.toString().padLeft(2, '0');
    final m = reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Met à jour l'heure du rappel, sauvegarde dans Hive et replanifie.
  Future<void> setReminderTime(int hour, int minute) async {
    try {
      await NotificationService.updateQuestReminderTime(hour, minute);
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: erreur setReminderTime: $e');
    }
  }
}
