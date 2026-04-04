import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/quest_model.dart';

void main() {
  group('QuestRarity', () {
    test('fromSupabaseString devrait retourner common si valeur inconnue', () {
      expect(
        QuestRarity.fromSupabaseString('inexistant'),
        QuestRarity.common,
      );
    });

    test('toSupabaseString devrait correspondre au nom de l\'enum', () {
      expect(QuestRarity.rare.toSupabaseString(), 'rare');
    });
  });

  group('QuestFrequency', () {
    test('one_off devrait se mapper correctement', () {
      expect(QuestFrequency.oneOff.toSupabaseString(), 'one_off');
      expect(
        QuestFrequency.fromSupabaseString('one_off'),
        QuestFrequency.oneOff,
      );
    });
  });

  group('QuestStatus', () {
    test('fromSupabaseString devrait retourner active si valeur inconnue', () {
      expect(
        QuestStatus.fromSupabaseString('???'),
        QuestStatus.active,
      );
    });
  });

  group('ValidationType', () {
    test('fromSupabaseString devrait retourner manual si valeur inconnue', () {
      expect(
        ValidationType.fromSupabaseString('xyz'),
        ValidationType.manual,
      );
    });
  });
}
