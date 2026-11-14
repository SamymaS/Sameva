import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/character_model.dart';
import '../providers.dart';

/// Apparence de l'avatar du joueur (genre, teint, coiffure), propre à chaque
/// compte et conservée sur l'appareil (boîte Hive `settings`).
///
/// Purement cosmétique : aucune ressource de jeu n'en dépend, elle n'a donc
/// pas à passer par le serveur (règle n°1). Elle y sera synchronisée avec
/// l'inventaire au Sprint 3.
class ApparenceAvatar extends Notifier<CharacterAppearance> {
  static String cle(String? uid) => 'avatar_apparence_${uid ?? 'invite'}';

  String? _uid;

  @override
  CharacterAppearance build() {
    _uid = ref.watch(currentUserIdProvider).valueOrNull;
    try {
      final brut = Hive.box('settings').get(cle(_uid));
      if (brut is Map) return CharacterAppearance.fromJson(Map<String, dynamic>.from(brut));
    } catch (_) {
      // Boîte fermée (tests) ou donnée illisible : apparence par défaut.
    }
    return const CharacterAppearance();
  }

  /// Modifie l'apparence à partir de sa valeur courante.
  Future<void> modifier(CharacterAppearance Function(CharacterAppearance) changement) => definir(changement(state));

  Future<void> definir(CharacterAppearance apparence) async {
    state = apparence;
    try {
      await Hive.box('settings').put(cle(_uid), apparence.toJson());
    } catch (_) {}
  }
}

final apparenceAvatarProvider = NotifierProvider<ApparenceAvatar, CharacterAppearance>(ApparenceAvatar.new);
