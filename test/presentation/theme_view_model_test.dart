import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sameva/presentation/view_models/theme_view_model.dart';

class _MockBox extends Mock implements Box<dynamic> {}

void main() {
  late _MockBox box;

  setUp(() {
    box = _MockBox();
    when(() => box.get(any())).thenReturn(null);
    when(() => box.put(any(), any())).thenAnswer((_) async => 0);
  });

  group('ThemeViewModel', () {
    test('devrait démarrer en ThemeMode.system si rien en base', () {
      final vm = ThemeViewModel(box);
      expect(vm.themeMode, ThemeMode.system);
    });

    test('setThemeMode devrait persister et notifier', () async {
      final vm = ThemeViewModel(box);
      await vm.setThemeMode(ThemeMode.dark);
      expect(vm.themeMode, ThemeMode.dark);
      verify(() => box.put('theme_mode', ThemeMode.dark.toString())).called(1);
    });
  });
}
