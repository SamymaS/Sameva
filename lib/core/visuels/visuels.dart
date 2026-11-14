import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Un visuel résolu : son fichier et la façon de l'agrandir.
@immutable
class Visuel {
  const Visuel(this.chemin, {this.pixel = true});

  /// Chemin de l'asset dans le bundle.
  final String chemin;

  /// Pixel art : agrandissement sans lissage. Faux pour une illustration ou un
  /// rendu 3D, qui doivent être lissés.
  final bool pixel;

  FilterQuality get filtre => pixel ? FilterQuality.none : FilterQuality.medium;

  @override
  bool operator ==(Object other) => other is Visuel && other.chemin == chemin && other.pixel == pixel;

  @override
  int get hashCode => Object.hash(chemin, pixel);
}

/// Catalogue des visuels et des sons de Sameva (ADR 0008).
///
/// Les écrans demandent un visuel par son **nom logique** (« l'objet
/// sword_rusty », « le chat lune », « MougiBot ») et ne connaissent aucun
/// chemin de fichier. Le catalogue répond d'abord avec la direction artistique
/// livrée (`assets/da/manifeste.json`), sinon avec le pixel art provisoire.
/// Remplacer un visuel = déposer un fichier et ajouter une ligne au manifeste :
/// aucun écran n'est modifié.
class Visuels {
  Visuels._();

  static const cheminManifeste = 'assets/da/manifeste.json';

  static Map<String, dynamic> _da = const {};

  /// Charge le manifeste de la direction artistique. Absent ou illisible : le
  /// catalogue reste sur le pixel art, sans erreur.
  static Future<void> charger([AssetBundle? bundle]) async {
    try {
      final texte = await (bundle ?? rootBundle).loadString(cheminManifeste);
      definirManifeste(jsonDecode(texte) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Visuels : pas de manifeste de DA ($e)');
      _da = const {};
    }
  }

  /// Remplace le manifeste (tests, rechargement).
  static void definirManifeste(Map<String, dynamic> manifeste) => _da = manifeste;

  static Map<String, dynamic> _section(String nom) {
    final s = _da[nom];
    return s is Map<String, dynamic> ? s : const {};
  }

  /// Les fichiers de la DA sont lissés, sauf si le manifeste dit `"pixel": true`.
  static bool get _daEnPixel => (_da['style'] is Map) && ((_da['style'] as Map)['pixel'] == true);

  static Visuel? _surcharge(String section, String cle) {
    final v = _section(section)[cle];
    return v is String && v.isNotEmpty ? Visuel(v, pixel: _daEnPixel) : null;
  }

  /// Nom logique d'un objet depuis son chemin historique
  /// (`assets/items/sword_rusty.svg` -> `sword_rusty`).
  static String? nomObjet(String? assetPath) {
    if (assetPath == null || assetPath.isEmpty) return null;
    return assetPath.split('/').last.split('.').first;
  }

  /// Icône d'un objet, ou null s'il n'a pas de visuel (icône de repli).
  static Visuel? objet(String? assetPath) {
    final nom = nomObjet(assetPath);
    if (nom == null) return null;
    return _surcharge('objets', nom) ?? Visuel('assets/sprites/objets/$nom.png');
  }

  /// Feuille de sprites d'un chat compagnon (mêmes animations que le manifeste pixel).
  static Visuel chat(String race) => _surcharge('chats', race) ?? Visuel('assets/sprites/chat_$race.png');

  /// Feuille de sprites de MougiBot.
  static Visuel get mougibot {
    final v = _da['mougibot'];
    return v is String && v.isNotEmpty ? Visuel(v, pixel: _daEnPixel) : const Visuel('assets/sprites/mougibot.png');
  }

  /// Illustration de l'avatar du joueur livrée par la DA, ou null : l'avatar
  /// provisoire dessiné par le code est alors utilisé.
  static Visuel? get avatar {
    final v = _da['avatar'];
    return v is String && v.isNotEmpty ? Visuel(v, pixel: _daEnPixel) : null;
  }

  /// Fichier d'un son (chemin relatif à `assets/`, attendu par audioplayers).
  static String son(String nom) {
    final v = _section('sons')[nom];
    final chemin = v is String && v.isNotEmpty ? v : 'assets/sfx/$nom.wav';
    return chemin.startsWith('assets/') ? chemin.substring('assets/'.length) : chemin;
  }
}

/// Image fixe issue du catalogue, avec le bon filtrage et un repli.
class ImageVisuel extends StatelessWidget {
  const ImageVisuel(this.visuel, {super.key, required this.cote, this.semanticLabel, this.repli});

  final Visuel visuel;
  final double cote;
  final String? semanticLabel;
  final Widget? repli;

  @override
  Widget build(BuildContext context) => Image.asset(
        visuel.chemin,
        width: cote,
        height: cote,
        fit: BoxFit.contain,
        filterQuality: visuel.filtre,
        isAntiAlias: !visuel.pixel,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (_, __, ___) => repli ?? SizedBox.square(dimension: cote),
      );
}
