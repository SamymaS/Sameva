import 'package:flutter/material.dart';

/// Genre du personnage
enum CharacterGender {
  male,
  female;

  String get label => switch (this) {
        CharacterGender.male => 'Masculin',
        CharacterGender.female => 'Féminin',
      };
}

/// Teintes de peau disponibles
enum SkinTone {
  light,
  medium,
  tan,
  dark,
  ebony;

  Color get color => switch (this) {
        SkinTone.light => const Color(0xFFFFE0BD),
        SkinTone.medium => const Color(0xFFECBF99),
        SkinTone.tan => const Color(0xFFC68642),
        SkinTone.dark => const Color(0xFF8D5524),
        SkinTone.ebony => const Color(0xFF3D1A00),
      };

  String get label => switch (this) {
        SkinTone.light => 'Claire',
        SkinTone.medium => 'Médium',
        SkinTone.tan => 'Hâlée',
        SkinTone.dark => 'Brune',
        SkinTone.ebony => 'Ébène',
      };
}

/// Styles de cheveux disponibles
enum HairStyle {
  short,
  medium,
  long,
  ponytail,
  bun,
  spiky;

  String get label => switch (this) {
        HairStyle.short => 'Court',
        HairStyle.medium => 'Mi-long',
        HairStyle.long => 'Long',
        HairStyle.ponytail => 'Queue',
        HairStyle.bun => 'Chignon',
        HairStyle.spiky => 'Hérissé',
      };

  IconData get icon => switch (this) {
        HairStyle.short => Icons.face,
        HairStyle.medium => Icons.person,
        HairStyle.long => Icons.person_2,
        HairStyle.ponytail => Icons.woman,
        HairStyle.bun => Icons.face_2,
        HairStyle.spiky => Icons.electric_bolt,
      };
}

/// Couleurs disponibles pour les cheveux
const List<Color> kHairColors = [
  Color(0xFF1A0A00), // Noir
  Color(0xFF4A2912), // Brun foncé
  Color(0xFF8B5E3C), // Brun
  Color(0xFFD4A056), // Blond doré
  Color(0xFFFFE4A0), // Blond clair
  Color(0xFFCC2222), // Rouge
  Color(0xFF8B008B), // Violet
  Color(0xFF009999), // Turquoise fantaisie
  Color(0xFFAAAAAA), // Gris
  Color(0xFFFFFFFF), // Blanc
];

/// Modèle d'apparence du personnage
class CharacterAppearance {
  final CharacterGender gender;
  final SkinTone skinTone;
  final Color hairColor;
  final HairStyle hairStyle;

  const CharacterAppearance({
    this.gender = CharacterGender.male,
    this.skinTone = SkinTone.medium,
    this.hairColor = const Color(0xFF4A2912),
    this.hairStyle = HairStyle.medium,
  });

  Map<String, dynamic> toJson() => {
        'gender': gender.name,
        'skinTone': skinTone.name,
        'hairColor': hairColor.value,
        'hairStyle': hairStyle.name,
      };

  factory CharacterAppearance.fromJson(Map<String, dynamic> json) =>
      CharacterAppearance(
        gender: CharacterGender.values.byName(
            (json['gender'] as String?) ?? CharacterGender.male.name),
        skinTone: SkinTone.values.byName(
            (json['skinTone'] as String?) ?? SkinTone.medium.name),
        hairColor: Color((json['hairColor'] as int?) ?? 0xFF4A2912),
        hairStyle: HairStyle.values.byName(
            (json['hairStyle'] as String?) ?? HairStyle.medium.name),
      );

  CharacterAppearance copyWith({
    CharacterGender? gender,
    SkinTone? skinTone,
    Color? hairColor,
    HairStyle? hairStyle,
  }) =>
      CharacterAppearance(
        gender: gender ?? this.gender,
        skinTone: skinTone ?? this.skinTone,
        hairColor: hairColor ?? this.hairColor,
        hairStyle: hairStyle ?? this.hairStyle,
      );
}
