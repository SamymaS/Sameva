import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/cat_model.dart';

void main() {
  group('CatStats — round-trip Supabase', () {
    final original = CatStats(
      id: 'abc-123',
      name: 'Braisette',
      race: 'braise',
      rarity: 'epic',
      isMain: true,
      equippedHat: 'hat-01',
      equippedOutfit: 'outfit-02',
      equippedPants: 'pants-03',
      equippedShoes: 'shoes-04',
      equippedAura: 'aura-05',
      equippedAccessory: 'acc-06',
      equippedTitle: 'title-07',
      obtainedAt: DateTime.utc(2025, 5, 16, 10, 0, 0),
    );

    test('toSupabaseMap produit les bonnes clés snake_case', () {
      final map = original.toSupabaseMap('user-xyz');

      expect(map['user_id'], 'user-xyz');
      expect(map['id'], 'abc-123');
      expect(map['name'], 'Braisette');
      expect(map['race'], 'braise');
      expect(map['rarity'], 'epic');
      expect(map['is_main'], isTrue);
      expect(map['equipped_hat'], 'hat-01');
      expect(map['equipped_outfit_cosmetic'], 'outfit-02');
      expect(map['equipped_pants'], 'pants-03');
      expect(map['equipped_shoes'], 'shoes-04');
      expect(map['equipped_aura'], 'aura-05');
      expect(map['equipped_accessory'], 'acc-06');
      expect(map['equipped_title'], 'title-07');
      expect(map['created_at'], '2025-05-16T10:00:00.000Z');
    });

    test('toSupabaseMap N\'inclut PAS mood, metadata, updated_at', () {
      final map = original.toSupabaseMap('user-xyz');

      expect(map.containsKey('mood'), isFalse);
      expect(map.containsKey('metadata'), isFalse);
      expect(map.containsKey('updated_at'), isFalse);
    });

    test('toSupabaseMap n\'inclut pas id si vide', () {
      final catSansId = CatStats(
        id: '',
        name: 'Sans ID',
        race: 'michi',
        obtainedAt: DateTime.now(),
      );
      final map = catSansId.toSupabaseMap('user-xyz');

      expect(map.containsKey('id'), isFalse);
    });

    test('fromSupabaseMap → toSupabaseMap préserve tous les champs', () {
      final map = original.toSupabaseMap('user-xyz');
      // Ajouter user_id dans le map pour simuler ce que Supabase retourne
      final supabaseRow = Map<String, dynamic>.from(map);

      final restored = CatStats.fromSupabaseMap(supabaseRow);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.race, original.race);
      expect(restored.rarity, original.rarity);
      expect(restored.isMain, original.isMain);
      expect(restored.equippedHat, original.equippedHat);
      expect(restored.equippedOutfit, original.equippedOutfit);
      expect(restored.equippedPants, original.equippedPants);
      expect(restored.equippedShoes, original.equippedShoes);
      expect(restored.equippedAura, original.equippedAura);
      expect(restored.equippedAccessory, original.equippedAccessory);
      expect(restored.equippedTitle, original.equippedTitle);
      expect(restored.obtainedAt, original.obtainedAt);
    });

    test('fromSupabaseMap applique les fallbacks pour valeurs inconnues', () {
      final restored = CatStats.fromSupabaseMap({
        'id': 'x',
        'name': 'Inconnu',
        'race': 'race_inconnue',
        'rarity': 'rarity_inconnue',
      });

      expect(restored.race, 'michi');
      expect(restored.rarity, 'common');
      expect(restored.isMain, isFalse);
      expect(restored.obtainedAt, isNotNull);
    });

    test('fromSupabaseMap avec tous les champs absents retourne un CatStats valide', () {
      final restored = CatStats.fromSupabaseMap({'id': 'y', 'name': 'Min'});

      expect(restored.equippedHat, isNull);
      expect(restored.equippedOutfit, isNull);
      expect(restored.equippedPants, isNull);
      expect(restored.equippedShoes, isNull);
      expect(restored.equippedAura, isNull);
      expect(restored.equippedAccessory, isNull);
      expect(restored.equippedTitle, isNull);
      expect(restored.isMain, isFalse);
    });
  });
}
