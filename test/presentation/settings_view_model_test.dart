import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/presentation/view_models/notification_view_model.dart';
import 'package:sameva/presentation/view_models/player_view_model.dart';
import 'package:sameva/presentation/view_models/settings_view_model.dart';
import 'package:sameva/presentation/view_models/theme_view_model.dart';

class _MockTheme extends Mock implements ThemeViewModel {}

class _MockNotif extends Mock implements NotificationViewModel {}

class _MockPlayer extends Mock implements PlayerViewModel {}

class _MockAuth extends Mock implements AuthViewModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  late _MockTheme theme;
  late _MockNotif notif;
  late _MockPlayer player;
  late _MockAuth auth;
  late SettingsViewModel vm;

  setUp(() {
    theme = _MockTheme();
    notif = _MockNotif();
    player = _MockPlayer();
    auth = _MockAuth();
    when(() => theme.themeMode).thenReturn(ThemeMode.light);
    when(() => notif.reminderHour).thenReturn(9);
    when(() => notif.reminderMinute).thenReturn(30);
    when(() => notif.reminderTimeLabel).thenReturn('09:30');
    vm = SettingsViewModel(theme, notif, player, auth);
  });

  tearDown(() {
    vm.dispose();
  });

  group('SettingsViewModel', () {
    test('isDark suit ThemeViewModel', () {
      when(() => theme.themeMode).thenReturn(ThemeMode.dark);
      expect(vm.isDark, isTrue);
    });

    test('setDarkMode bascule le thème', () async {
      when(() => theme.setThemeMode(any())).thenAnswer((_) async {});

      await vm.setDarkMode(true);

      verify(() => theme.setThemeMode(ThemeMode.dark)).called(1);
    });

    test('expose l\'heure de rappel depuis NotificationViewModel', () {
      expect(vm.reminderHour, 9);
      expect(vm.reminderMinute, 30);
      expect(vm.reminderTimeLabel, '09:30');
    });

    test('setReminderTime délègue au NotificationViewModel', () async {
      when(() => notif.setReminderTime(any(), any())).thenAnswer((_) async {});

      await vm.setReminderTime(14, 15);

      verify(() => notif.setReminderTime(14, 15)).called(1);
    });

    test('resetPlayer utilise userId puis PlayerViewModel', () async {
      when(() => auth.userId).thenReturn('uid-z');
      when(() => player.resetPlayer('uid-z')).thenAnswer((_) async {});

      await vm.resetPlayer();

      verify(() => player.resetPlayer('uid-z')).called(1);
    });

    test('resetPlayer avec userId null appelle reset avec chaîne vide', () async {
      when(() => auth.userId).thenReturn(null);
      when(() => player.resetPlayer('')).thenAnswer((_) async {});

      await vm.resetPlayer();

      verify(() => player.resetPlayer('')).called(1);
    });
  });
}
