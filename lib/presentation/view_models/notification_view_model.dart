import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/services/notification_service.dart';

/// ViewModel pour le rappel quotidien de quêtes.
/// L'heure est persistée dans la boîte Hive 'settings'.
class NotificationViewModel with ChangeNotifier {
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  final Box _box;
  final Future<void> Function(int hour, int minute) _persistAndSchedule;

  NotificationViewModel(
    this._box, {
    Future<void> Function(int hour, int minute)? persistAndScheduleReminder,
  }) : _persistAndSchedule =
            persistAndScheduleReminder ?? NotificationService.updateQuestReminderTime;

  int get reminderHour => _box.get(_keyHour, defaultValue: 9) as int;
  int get reminderMinute => _box.get(_keyMinute, defaultValue: 0) as int;

  String get reminderTimeLabel {
    final h = reminderHour.toString().padLeft(2, '0');
    final m = reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> setReminderTime(int hour, int minute) async {
    try {
      await _persistAndSchedule(hour, minute);
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationViewModel: erreur setReminderTime: $e');
    }
  }
}
