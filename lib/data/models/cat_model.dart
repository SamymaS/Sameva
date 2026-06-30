/// Modèle représentant un chat compagnon (companion virtuel du joueur).
/// Stocké en JSON dans la boîte Hive 'cats'.
class CatStats {
  final String id;
  final String name;         // Nom personnalisé par le joueur
  final String race;         // michi | lune | braise | neige | cosmos | sakura
  final String rarity;       // common | uncommon | rare | epic | legendary | mythic
  final bool isMain;         // true = chat principal affiché
  final String? equippedHat;
  final String? equippedOutfit;
  final String? equippedPants;
  final String? equippedShoes;
  final String? equippedAura;
  final String? equippedAccessory;
  final String? equippedTitle;
  final DateTime obtainedAt;

  const CatStats({
    required this.id,
    required this.name,
    required this.race,
    this.rarity = 'common',
    this.isMain = false,
    this.equippedHat,
    this.equippedOutfit,
    this.equippedPants,
    this.equippedShoes,
    this.equippedAura,
    this.equippedAccessory,
    this.equippedTitle,
    required this.obtainedAt,
  });

  /// Sérialisation vers Supabase (snake_case, colonnes de la table companions).
  /// [userId] est passé explicitement car CatStats ne stocke pas de userId.
  /// Les champs dormants (mood, metadata, updated_at) sont intentionnellement
  /// absents : les DEFAULT et triggers SQL font le travail.
  Map<String, dynamic> toSupabaseMap(String userId) {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'race': race,
      'rarity': rarity,
      'is_main': isMain,
      'equipped_hat': equippedHat,
      'equipped_outfit_cosmetic': equippedOutfit,
      'equipped_pants': equippedPants,
      'equipped_shoes': equippedShoes,
      'equipped_aura': equippedAura,
      'equipped_accessory': equippedAccessory,
      'equipped_title': equippedTitle,
      'created_at': obtainedAt.toIso8601String(),
    };
    // N'inclut id que s'il est non-vide (Postgres génère un UUID via DEFAULT).
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  /// Désérialisation depuis une ligne Supabase (snake_case).
  static CatStats fromSupabaseMap(Map<String, dynamic> map) => CatStats(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        race: _safeRace(map['race'] as String?),
        rarity: _safeRarity(map['rarity'] as String?),
        isMain: map['is_main'] as bool? ?? false,
        equippedHat: map['equipped_hat'] as String?,
        equippedOutfit: map['equipped_outfit_cosmetic'] as String?,
        equippedPants: map['equipped_pants'] as String?,
        equippedShoes: map['equipped_shoes'] as String?,
        equippedAura: map['equipped_aura'] as String?,
        equippedAccessory: map['equipped_accessory'] as String?,
        equippedTitle: map['equipped_title'] as String?,
        obtainedAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
      );

  static const _validRaces = {
    'michi', 'lune', 'braise', 'neige', 'cosmos', 'sakura'
  };
  static const _validRarities = {
    'common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'
  };

  static String _safeRace(String? value) =>
      (_validRaces.contains(value)) ? value! : 'michi';

  static String _safeRarity(String? value) =>
      (_validRarities.contains(value)) ? value! : 'common';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'race': race,
        'rarity': rarity,
        'isMain': isMain,
        'equippedHat': equippedHat,
        'equippedOutfit': equippedOutfit,
        'equippedPants': equippedPants,
        'equippedShoes': equippedShoes,
        'equippedAura': equippedAura,
        'equippedAccessory': equippedAccessory,
        'equippedTitle': equippedTitle,
        'obtainedAt': obtainedAt.toIso8601String(),
      };

  factory CatStats.fromJson(Map<String, dynamic> json) => CatStats(
        id: json['id'] as String,
        name: json['name'] as String,
        race: json['race'] as String,
        rarity: json['rarity'] as String? ?? 'common',
        isMain: json['isMain'] as bool? ?? false,
        equippedHat: json['equippedHat'] as String?,
        equippedOutfit: json['equippedOutfit'] as String?,
        equippedPants: json['equippedPants'] as String?,
        equippedShoes: json['equippedShoes'] as String?,
        equippedAura: json['equippedAura'] as String?,
        equippedAccessory: json['equippedAccessory'] as String?,
        equippedTitle: json['equippedTitle'] as String?,
        obtainedAt: DateTime.parse(json['obtainedAt'] as String),
      );

  CatStats copyWith({
    String? id,
    String? name,
    String? race,
    String? rarity,
    bool? isMain,
    Object? equippedHat = _sentinel,
    Object? equippedOutfit = _sentinel,
    Object? equippedPants = _sentinel,
    Object? equippedShoes = _sentinel,
    Object? equippedAura = _sentinel,
    Object? equippedAccessory = _sentinel,
    Object? equippedTitle = _sentinel,
    DateTime? obtainedAt,
  }) =>
      CatStats(
        id: id ?? this.id,
        name: name ?? this.name,
        race: race ?? this.race,
        rarity: rarity ?? this.rarity,
        isMain: isMain ?? this.isMain,
        equippedHat: equippedHat == _sentinel
            ? this.equippedHat
            : equippedHat as String?,
        equippedOutfit: equippedOutfit == _sentinel
            ? this.equippedOutfit
            : equippedOutfit as String?,
        equippedPants: equippedPants == _sentinel
            ? this.equippedPants
            : equippedPants as String?,
        equippedShoes: equippedShoes == _sentinel
            ? this.equippedShoes
            : equippedShoes as String?,
        equippedAura: equippedAura == _sentinel
            ? this.equippedAura
            : equippedAura as String?,
        equippedAccessory: equippedAccessory == _sentinel
            ? this.equippedAccessory
            : equippedAccessory as String?,
        equippedTitle: equippedTitle == _sentinel
            ? this.equippedTitle
            : equippedTitle as String?,
        obtainedAt: obtainedAt ?? this.obtainedAt,
      );
}

/// Sentinelle pour distinguer null explicite de "non fourni" dans copyWith.
const _sentinel = Object();
