import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Service de notifications locales.
/// - ID 0 : rappel quêtes du matin (heure configurable, défaut 9h)
/// - ID 1 : rappel streak du soir (20h quotidien, annulable si quête complétée)
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelQuests = AndroidNotificationDetails(
    'quest_reminder',
    'Rappel de quêtes',
    channelDescription: 'Rappels quotidiens pour vos quêtes',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _channelStreak = AndroidNotificationDetails(
    'streak_reminder',
    'Rappel de série',
    channelDescription: 'Ne brisez pas votre série !',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );

      // Demande permission Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Lecture de l'heure configurée (Hive settings, défaut 9h00)
      final box = Hive.box('settings');
      final hour = box.get('reminder_hour', defaultValue: 9) as int;
      final minute = box.get('reminder_minute', defaultValue: 0) as int;

      await scheduleQuestReminder(hour: hour, minute: minute);
      await scheduleStreakReminder();
    } catch (e) {
      debugPrint('NotificationService: erreur init: $e');
    }
  }

  /// Rappel quotidien à l'heure donnée (défaut 9h00).
  static Future<void> scheduleQuestReminder({int hour = 9, int minute = 0}) async {
    try {
      await _plugin.cancel(0);
      await _plugin.zonedSchedule(
        0,
        'Vos quêtes vous attendent !',
        'Complétez vos quêtes du jour pour maintenir votre série.',
        _nextTime(hour, minute),
        NotificationDetails(android: _channelQuests, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: erreur rappel quêtes: $e');
    }
  }

  /// Met à jour l'heure du rappel quêtes et sauvegarde dans Hive.
  static Future<void> updateQuestReminderTime(int hour, int minute) async {
    try {
      final box = Hive.box('settings');
      await box.put('reminder_hour', hour);
      await box.put('reminder_minute', minute);
      await scheduleQuestReminder(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('NotificationService: erreur mise à jour heure rappel: $e');
    }
  }

  /// Rappel streak à 20h. À annuler dès qu'une quête est complétée.
  static Future<void> scheduleStreakReminder() async {
    try {
      await _plugin.zonedSchedule(
        1,
        'Ne brisez pas votre série !',
        "Vous n'avez pas encore complété de quête aujourd'hui.",
        _nextTime(20, 0),
        NotificationDetails(android: _channelStreak, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: erreur rappel streak: $e');
    }
  }

  /// Appeler quand une quête est complétée aujourd'hui → annule le rappel streak.
  static Future<void> cancelStreakReminder() async {
    try {
      await _plugin.cancel(1);
    } catch (e) {
      debugPrint('NotificationService: erreur annulation streak: $e');
    }
  }

  /// Notification immédiate lors d'un jalon de streak.
  static Future<void> showStreakMilestone(int days, String rarity) async {
    try {
      const channel = AndroidNotificationDetails(
        'streak_milestone',
        'Jalons de série',
        channelDescription: 'Récompenses débloquées pour les séries',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      await _plugin.show(
        2,
        '🎉 $days jours de suite !',
        'Tu as débloqué un cosmétique $rarity pour ton chat !',
        const NotificationDetails(
            android: channel, iOS: DarwinNotificationDetails()),
      );
    } catch (e) {
      debugPrint('NotificationService: erreur jalon streak: $e');
    }
  }

  /// Replanifier le streak pour le lendemain (appelé après annulation).
  static Future<void> rescheduleStreakReminder() async {
    await cancelStreakReminder();
    await scheduleStreakReminder();
  }

  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
