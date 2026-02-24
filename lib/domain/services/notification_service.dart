import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Service de notifications locales.
/// - ID 0 : rappel quêtes du matin (9h quotidien)
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

      await _scheduleAll();
    } catch (e) {
      debugPrint('NotificationService: erreur init: $e');
    }
  }

  /// Planifie le rappel quêtes (9h) et le rappel streak (20h).
  static Future<void> _scheduleAll() async {
    await scheduleQuestReminder();
    await scheduleStreakReminder();
  }

  /// Rappel quotidien à 9h : "Vos quêtes vous attendent !"
  static Future<void> scheduleQuestReminder() async {
    try {
      await _plugin.zonedSchedule(
        0,
        'Vos quêtes vous attendent !',
        'Complétez vos quêtes du jour pour maintenir votre série.',
        _nextTime(9, 0),
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
