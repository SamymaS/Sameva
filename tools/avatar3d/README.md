# Avatar 2.5D : du modèle Blender aux images de l'application

L'avatar du joueur est un personnage **modélisé en 3D**, puis **rendu en images**
sous 8 angles (« 3D pré-rendue », ou 2.5D). L'application n'embarque pas de
moteur 3D pour lui : elle empile des images et les teinte.

## Le principe des couches

Chaque pièce est rendue **seule et en blanc** : corps, haut, bas, chaussures,
visage, sourcils, chaque coiffure, chaque chapeau. Pendant le rendu d'une pièce,
les autres la masquent comme dans la réalité (objets « holdout » de Blender) :
une manche passe devant le buste, les cheveux longs derrière l'épaule.

L'application empile ensuite les couches et multiplie chacune par une couleur
(peau, cheveux, couleur du cosmétique équipé). Une seule série d'images couvre
ainsi toutes les combinaisons : 2 silhouettes × 5 teints × 6 coiffures ×
10 couleurs × toutes les tenues.

## Régénérer

```bash
# Blender 5.x installé :
blender -b -P tools/avatar3d/generer_avatar.py -- --sortie assets/avatar --blend avatar_sameva.blend
# ou avec le module Python (pip install bpy) :
python tools/avatar3d/generer_avatar.py -- --sortie assets/avatar
```

| Option | Effet |
| --- | --- |
| `--sortie <dossier>` | Dossier des feuilles et du `manifeste.json` (défaut : `assets/avatar`) |
| `--blend <fichier>` | Enregistre aussi la scène Blender, pour la retravailler à la main |
| `--apercu` | 2 angles seulement, pour itérer vite |
| `--echantillons <n>` | Qualité du rendu Cycles (défaut : 48) |

Sortie : une feuille PNG par couche (8 images de 320 × 640 côte à côte, de face
puis en tournant) et `manifeste.json`. Lecture côté application :
`lib/ui/widgets/avatar/avatar_joueur.dart`.

## Remplacer le modèle provisoire

Le personnage actuel est construit par le script à partir de formes simples :
c'est un **provisoire**. Pour le remplacer par un vrai modèle :

1. garder les **noms de couches** (`corps_male`, `haut_female`, `cheveux_bun`,
   `chapeau_2`…), la taille des images et les 8 angles ;
2. garder des matières **blanches** sur tout ce qui doit être teinté, et des
   couleurs propres sur le visage (yeux, bouche) ;
3. rendre avec la fonction `rendre()` du script (elle gère les masques), dans un
   dossier `assets/da/avatar/` ;
4. déclarer ce dossier dans `assets/da/manifeste.json` (`"avatar": "assets/da/avatar"`)
   et dans `pubspec.yaml`.

Aucun écran n'est à modifier (ADR 0008).

## Ajouter une pièce

Une nouvelle coiffure ou un nouveau chapeau = une fonction de modelage dans le
script, son nom dans `COIFFURES` ou `CHAPEAUX`, un nouveau rendu. Côté
application, une coiffure demande une valeur dans `HairStyle`
(`lib/data/models/character_model.dart`) ; un chapeau, un `styleIndex` d'objet.
