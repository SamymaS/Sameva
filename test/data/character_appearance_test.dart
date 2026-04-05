import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/data/models/character_model.dart';

void main() {
  group('CharacterAppearance', () {
    test('toJson puis fromJson préserve les champs', () {
      const original = CharacterAppearance(
        gender: CharacterGender.female,
        skinTone: SkinTone.tan,
        hairColor: Color(0xFFCC2222),
        hairStyle: HairStyle.ponytail,
      );

      final json = original.toJson();
      final restored = CharacterAppearance.fromJson(json);

      expect(restored.gender, original.gender);
      expect(restored.skinTone, original.skinTone);
      expect(restored.hairColor, original.hairColor);
      expect(restored.hairStyle, original.hairStyle);
    });

    test('fromJson tolère les champs absents', () {
      final s = CharacterAppearance.fromJson({});

      expect(s.gender, CharacterGender.male);
      expect(s.skinTone, SkinTone.medium);
      expect(s.hairStyle, HairStyle.medium);
    });

    test('copyWith remplace sélectivement', () {
      const base = CharacterAppearance();
      final c = base.copyWith(hairStyle: HairStyle.bun);

      expect(c.hairStyle, HairStyle.bun);
      expect(c.gender, base.gender);
    });
  });
}
