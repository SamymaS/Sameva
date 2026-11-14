import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ce qui vient de se passer dans le jeu, du point de vue du joueur.
enum TypeEvenement {
  /// Navigation ou appui sur un élément d'interface.
  toucher,
  pieceGagnee,
  degats,
  queteAccomplie,
  niveauSuperieur,
  oracleObserve,
  oracleAccepte,
  oracleRefuse,

  /// Révélation d'une invocation ; [EvenementJeu.rarete] porte la rareté.
  invocation,
}

@immutable
class EvenementJeu {
  const EvenementJeu(this.type, {this.rarete});

  final TypeEvenement type;

  /// Rareté serveur (`common`, `rare`, `epic`, `legendary`, `mythic`), pour une invocation.
  final String? rarete;

  @override
  String toString() => 'EvenementJeu(${type.name}${rarete == null ? '' : ', $rarete'})';
}

/// Bus des événements de jeu (ADR 0008).
///
/// Les écrans **annoncent** ce qui se passe (`BusJeu.emettre`) sans savoir quel
/// son, quelle vibration ou quelle animation en découle. Les réactions sont
/// décidées ailleurs, dans des tables (voir `Ambiance`) : changer un son ou en
/// ajouter un ne touche plus aucun écran.
class BusJeu {
  BusJeu._();

  static final StreamController<EvenementJeu> _flux = StreamController<EvenementJeu>.broadcast(sync: true);

  static Stream<EvenementJeu> get flux => _flux.stream;

  static void emettre(TypeEvenement type, {String? rarete}) => _flux.add(EvenementJeu(type, rarete: rarete));
}
