import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/services/notification_service.dart';
import 'auth_view_model.dart';
import 'notification_view_model.dart';
import 'player_view_model.dart';
import 'theme_view_model.dart';

/// ViewModel de la page Paramètres.
/// Agrège [ThemeViewModel], [NotificationViewModel], [PlayerViewModel] et [AuthViewModel]
/// en un seul point d'entrée pour la page.
class SettingsViewModel extends ChangeNotifier {
  final ThemeViewModel _themeVM;
  final NotificationViewModel _notifVM;
  final PlayerViewModel _playerVM;
  final AuthViewModel _authVM;

  SettingsViewModel(
    this._themeVM,
    this._notifVM,
    this._playerVM,
    this._authVM,
  ) {
    _themeVM.addListener(_onChange);
    _notifVM.addListener(_onChange);
    _playerVM.addListener(_onChange);
    _authVM.addListener(_onChange);
  }

  void _onChange() => notifyListeners();

  // ── Thème ──────────────────────────────────────────────────────────────────

  bool get isDark => _themeVM.themeMode == ThemeMode.dark;

  Future<void> setDarkMode(bool value) =>
      _themeVM.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);

  // ── Notifications ──────────────────────────────────────────────────────────

  int get reminderHour => _notifVM.reminderHour;
  int get reminderMinute => _notifVM.reminderMinute;
  String get reminderTimeLabel => _notifVM.reminderTimeLabel;

  Future<void> setReminderTime(int hour, int minute) =>
      _notifVM.setReminderTime(hour, minute);

  // ── Toggles notifications ──────────────────────────────────────────────────

  static const _keyStreakNotif    = 'streak_notif_enabled';
  static const _keyDeadlineNotif  = 'deadline_notif_enabled';

  bool get streakNotifEnabled =>
      Hive.box('settings').get(_keyStreakNotif, defaultValue: true) as bool;

  bool get deadlineNotifEnabled =>
      Hive.box('settings').get(_keyDeadlineNotif, defaultValue: true) as bool;

  Future<void> setStreakNotif(bool enabled) async {
    await Hive.box('settings').put(_keyStreakNotif, enabled);
    if (enabled) {
      await NotificationService.scheduleStreakReminder();
    } else {
      await NotificationService.cancelStreakReminder();
    }
    notifyListeners();
  }

  Future<void> setDeadlineNotif(bool enabled) async {
    await Hive.box('settings').put(_keyDeadlineNotif, enabled);
    notifyListeners();
  }

  // ── Joueur ─────────────────────────────────────────────────────────────────

  Future<void> resetPlayer() {
    final userId = _authVM.userId ?? '';
    return _playerVM.resetPlayer(userId);
  }

  @override
  void dispose() {
    _themeVM.removeListener(_onChange);
    _notifVM.removeListener(_onChange);
    _playerVM.removeListener(_onChange);
    _authVM.removeListener(_onChange);
    super.dispose();
  }
}
