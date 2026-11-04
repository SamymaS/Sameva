import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Effets sonores chiptune de Sameva (assets/sfx, générés par tools/pixel).
enum Son {
  toucher('ui_toucher'),
  piece('piece'),
  queteAccomplie('quete_accomplie'),
  niveauSuperieur('niveau_superieur'),
  oracleObserve('oracle_observe'),
  oracleAccepte('oracle_accepte'),
  oracleRefuse('oracle_refuse'),
  invocationCommune('invocation_commune'),
  invocationRare('invocation_rare'),
  invocationLegendaire('invocation_legendaire'),
  degats('degats');

  const Son(this.fichier);
  final String fichier;
}

/// Lecture des sons, coupable dans les réglages (`sons_actifs`, Hive settings).
///
/// Jamais bloquant : une erreur de lecture (plateforme sans audio, tests) est
/// ignorée silencieusement, le jeu continue sans son.
class Sons {
  Sons._();

  static const cleReglage = 'sons_actifs';
  static final Map<Son, AudioPlayer> _lecteurs = {};

  /// Désactivable dans les tests.
  @visibleForTesting
  static bool desactiveGlobalement = false;

  static bool get actifs {
    // Web : version de banc d'essai uniquement ; le greffon audio web de
    // audioplayers 6 n'y initialise pas son canal global. Sons sur mobile.
    if (desactiveGlobalement || kIsWeb) return false;
    try {
      return Hive.box('settings').get(cleReglage, defaultValue: true) as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<void> definirActifs(bool valeur) async {
    try {
      await Hive.box('settings').put(cleReglage, valeur);
    } catch (_) {}
  }

  /// Rarité serveur (`common`, `rare`, `epic`, `legendary`...) → son d'invocation.
  static Son invocationPour(String rarete) => switch (rarete.toLowerCase()) {
        'legendary' || 'legendaire' || 'mythic' || 'mythique' => Son.invocationLegendaire,
        'rare' || 'epic' || 'epique' => Son.invocationRare,
        _ => Son.invocationCommune,
      };

  static Future<void> jouer(Son son) async {
    if (!actifs) return;
    try {
      var lecteur = _lecteurs[son];
      if (lecteur == null) {
        lecteur = _lecteurs[son] = AudioPlayer();
        if (!kIsWeb) await lecteur.setPlayerMode(PlayerMode.lowLatency);
      }
      await lecteur.stop();
      await lecteur.play(AssetSource('sfx/${son.fichier}.wav'), volume: 0.7);
    } catch (e) {
      debugPrint('Sons: lecture impossible (${son.fichier}) : $e');
    }
  }
}
