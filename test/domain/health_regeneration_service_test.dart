import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sameva/domain/services/health_regeneration_service.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dir = await Directory.systemTemp.createTemp('sameva_hp_regen_');
    Hive.init(dir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box('settings').close();
    }
    await Hive.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  tearDown(() async {
    await Hive.box('settings').clear();
  });

  group('HealthRegenerationService', () {
    test('ne régénère pas si les HP sont déjà au maximum', () {
      final r = HealthRegenerationService.computeRegen(
        currentHp: 100,
        maxHp: 100,
      );
      expect(r, 0);
    });

    test('première exécution sans historique initialise l\'horodatage et retourne 0',
        () {
      final r = HealthRegenerationService.computeRegen(
        currentHp: 50,
        maxHp: 100,
      );
      expect(r, 0);
    });

    test('régénère après plus d\'une heure selon le pourcentage horaire', () async {
      final box = Hive.box('settings');
      await box.put(
        'last_hp_regen_at',
        DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      );

      final regen = HealthRegenerationService.computeRegen(
        currentHp: 50,
        maxHp: 100,
      );

      expect(regen, 20);
    });

    test('plafonne l\'effet à 8 heures maximum', () async {
      final box = Hive.box('settings');
      await box.put(
        'last_hp_regen_at',
        DateTime.now().subtract(const Duration(hours: 100)).toIso8601String(),
      );

      final regen = HealthRegenerationService.computeRegen(
        currentHp: 10,
        maxHp: 100,
      );

      expect(regen, 80);
    });

    test('previewRegen ne modifie pas l\'horodatage', () async {
      final box = Hive.box('settings');
      final past = DateTime.now().subtract(const Duration(hours: 3));
      await box.put('last_hp_regen_at', past.toIso8601String());

      final preview = HealthRegenerationService.previewRegen(maxHp: 100);
      expect(preview, greaterThan(0));

      final raw = box.get('last_hp_regen_at') as String;
      expect(DateTime.parse(raw), past);
    });

    test('previewRegen retourne 0 sans historique', () {
      expect(HealthRegenerationService.previewRegen(maxHp: 100), 0);
    });
  });
}
