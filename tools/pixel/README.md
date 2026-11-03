# Pixel art et sons de Sameva

## Images (Figma)

Les planches sont générées dans le fichier Figma **Sameva · Pixel art**
(https://www.figma.com/design/JPJpwdPnsvXuE5n4D38SIP) avec le modèle d'image de
Figma, puis converties en sprites :

1. Exporter chaque planche listée dans `PLANCHES` (`importer_figma.py`) en PNG,
   sous le nom indiqué, dans un même dossier.
2. `python3 tools/pixel/importer_figma.py <dossier>`

Le script découpe les cellules, retire le fond (et les tuiles éventuelles),
ramène chaque image sur une grille fixe (96 px personnages, 32 px objets),
applique une palette commune et écrit `assets/sprites/` + `animations.json`.

Pour une nouvelle planche : garder la consigne de style (fond bleu nuit uni
#141226, grille stricte lignes × colonnes, grands espaces, même échelle,
contour prune 1 px, lumière en haut à gauche) puis l'ajouter à `PLANCHES`.

## Sons

`python3 tools/pixel/sfx.py assets/sfx` (chiptune synthétisé, sans échantillon externe).
