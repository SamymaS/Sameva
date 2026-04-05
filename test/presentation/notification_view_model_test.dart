import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/presentation/view_models/notification_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  late _MockBox box;

  setUp(() {
    box = _MockBox();
    when(() => box.put(any(), any())).thenAnswer((_) async {});
  });

  group('NotificationViewModel', () {
    test('reminderHour et reminderMinute lisent la box avec défauts', () {
      when(() => box.get('reminder_hour', defaultValue: 9)).thenReturn(14);
      when(() => box.get('reminder_minute', defaultValue: 0)).thenReturn(45);

      final vm = NotificationViewModel(box);

      expect(vm.reminderHour, 14);
      expect(vm.reminderMinute, 45);
      expect(vm.reminderTimeLabel, '14:45');
    });

    test('reminderTimeLabel pad les zéros', () {
      when(() => box.get('reminder_hour', defaultValue: 9)).thenReturn(8);
      when(() => box.get('reminder_minute', defaultValue: 0)).thenReturn(5);

      final vm = NotificationViewModel(box);

      expect(vm.reminderTimeLabel, '08:05');
    });

    test('setReminderTime avec injecté persiste sans NotificationService', () async {
      when(() => box.get('reminder_hour', defaultValue: 9)).thenReturn(9);
      when(() => box.get('reminder_minute', defaultValue: 0)).thenReturn(0);

      Future<void> fakePersist(int h, int m) async {
        await box.put('reminder_hour', h);
        await box.put('reminder_minute', m);
      }

      final vm = NotificationViewModel(
        box,
        persistAndScheduleReminder: fakePersist,
      );

      await vm.setReminderTime(21, 15);

      verify(() => box.put('reminder_hour', 21)).called(1);
      verify(() => box.put('reminder_minute', 15)).called(1);
    });

    test('setReminderTime ignore les erreurs du callback', () async {
      when(() => box.get('reminder_hour', defaultValue: 9)).thenReturn(9);
      when(() => box.get('reminder_minute', defaultValue: 0)).thenReturn(0);

      final vm = NotificationViewModel(
        box,
        persistAndScheduleReminder: (_, __) async {
          throw Exception('plugin');
        },
      );

      await expectLater(vm.setReminderTime(1, 1), completes);
    });
  });
}
