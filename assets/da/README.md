# Direction artistique : dépôt des visuels et des sons définitifs

Ce dossier reçoit les créations de la direction artistique. L'application
cherche chaque visuel **d'abord ici**, puis retombe sur le pixel art provisoire
(`assets/sprites/`, `assets/sfx/`). Remplacer un visuel ne demande donc aucune
modification du code : un fichier et une ligne dans `manifeste.json`.

## Le manifeste

```json
{
  "style": { "pixel": false },
  "objets": { "sword_rusty": "assets/da/objets/sword_rusty.png" },
  "chats": { "lune": "assets/da/chats/lune.png" },
  "mougibot": "assets/da/mougibot.png",
  "avatar": "assets/da/avatar",
  "sons": { "quete_accomplie": "assets/da/sfx/quete_accomplie.ogg" }
}
```

| Clé | Contenu | Remarques |
| --- | --- | --- |
| `style.pixel` | `true` si les fichiers sont du pixel art | Sinon les images sont lissées à l'agrandissement |
| `objets` | Une icône carrée par objet | Les noms sont ceux de `assets/sprites/objets/` |
| `chats` | Une feuille de sprites par race | Même découpage que `assets/sprites/animations.json` |
| `mougibot` | La feuille de sprites de MougiBot | Même découpage que le manifeste des animations |
| `avatar` | Le dossier des couches de l'avatar (son `manifeste.json` et une feuille par couche) | Produit par `tools/avatar3d/generer_avatar.py` depuis le modèle Blender ; vide : avatar provisoire |
| `sons` | Un fichier par son | Les noms sont ceux de `assets/sfx/` |

Une clé absente ou vide garde le visuel provisoire.

## À ne pas oublier

- Chaque sous-dossier créé ici doit être déclaré dans `pubspec.yaml`
  (section `flutter: assets:`), par exemple `- assets/da/objets/`.
- PNG à fond transparent, noms en minuscules, sans espaces ni accents.
- Le code qui lit ce manifeste : `lib/core/visuels/visuels.dart` (ADR 0008).
