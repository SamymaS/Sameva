import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../audio/sons.dart';
import 'evenements_jeu.dart';

/// Intensité d'une vibration.
enum Vibration { aucune, legere, moyenne, forte }

/// Traduit les événements de jeu en sons et en vibrations (ADR 0008).
///
/// Tout le « ressenti » de l'application tient dans les deux tables ci-dessous.
class Ambiance {
  Ambiance._();

  static const cleVibrations = 'vibrations_actives';
  static StreamSubscription<EvenementJeu>? _abonnement;

  /// Son joué pour un événement (null : silence).
  static Son? sonPour(EvenementJeu e) => switch (e.type) {
        TypeEvenement.toucher => Son.toucher,
        TypeEvenement.pieceGagnee => Son.piece,
        TypeEvenement.degats => Son.degats,
        TypeEvenement.queteAccomplie => Son.queteAccomplie,
        TypeEvenement.niveauSuperieur => Son.niveauSuperieur,
        TypeEvenement.oracleObserve => Son.oracleObserve,
        TypeEvenement.oracleAccepte => Son.oracleAccepte,
        TypeEvenement.oracleRefuse => Son.oracleRefuse,
        TypeEvenement.invocation => Sons.invocationPour(e.rarete ?? 'common'),
      };

  /// Vibration associée à un événement.
  static Vibration vibrationPour(EvenementJeu e) => switch (e.type) {
        TypeEvenement.toucher || TypeEvenement.oracleObserve => Vibration.aucune,
        TypeEvenement.pieceGagnee => Vibration.legere,
        TypeEvenement.queteAccomplie || TypeEvenement.oracleAccepte => Vibration.moyenne,
        TypeEvenement.degats || TypeEvenement.oracleRefuse || TypeEvenement.niveauSuperieur => Vibration.forte,
        TypeEvenement.invocation =>
          Sons.invocationPour(e.rarete ?? 'common') == Son.invocationCommune ? Vibration.legere : Vibration.forte,
      };

  static bool get vibrationsActives {
    if (kIsWeb) return false;
    try {
      return Hive.box('settings').get(cleVibrations, defaultValue: true) as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<void> definirVibrations(bool valeur) async {
    try {
      await Hive.box('settings').put(cleVibrations, valeur);
    } catch (_) {}
  }

  /// Branche l'ambiance sur le bus. À appeler une fois au démarrage.
  static void demarrer() {
    _abonnement ??= BusJeu.flux.listen(_reagir);
  }

  @visibleForTesting
  static Future<void> arreter() async {
    await _abonnement?.cancel();
    _abonnement = null;
  }

  static void _reagir(EvenementJeu e) {
    final son = sonPour(e);
    if (son != null) unawaited(Sons.jouer(son));
    if (vibrationsActives) unawaited(vibrer(vibrationPour(e)));
  }

  static Future<void> vibrer(Vibration v) async {
    try {
      switch (v) {
        case Vibration.aucune:
          return;
        case Vibration.legere:
          await HapticFeedback.lightImpact();
        case Vibration.moyenne:
          await HapticFeedback.mediumImpact();
        case Vibration.forte:
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      // Plateforme sans moteur de vibration : sans effet.
    }
  }
}
