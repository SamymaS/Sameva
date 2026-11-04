"""Découpe une planche d'icônes générée dans Figma (grille lignes × colonnes,
fond uni) en icônes pixel art 32 × 32 à fond transparent.

    python3 tools/pixel/icones_depuis_planche.py planche.png 2x5 nom1,nom2,... dossier/
"""
import sys
from collections import deque

import numpy as np
from PIL import Image

TAILLE = 32


def _remplir(a, graines, accepte):
    """Remplissage par diffusion depuis les graines, à travers les pixels acceptés."""
    h, w, _ = a.shape
    vu = np.zeros((h, w), bool)
    q = deque(g for g in graines if accepte[g])
    while q:
        y, x = q.popleft()
        if vu[y, x]:
            continue
        vu[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            Y, X = y + dy, x + dx
            if 0 <= Y < h and 0 <= X < w and not vu[Y, X] and accepte[Y, X]:
                q.append((Y, X))
    return vu


def detourer(cellule):
    """Fond transparent en deux temps : le fond de la planche depuis les bords
    de la cellule, puis la tuile éventuelle (carré plus clair que le modèle
    dessine parfois derrière l'objet) depuis les bords de cette tuile."""
    a = np.asarray(cellule.convert("RGB")).astype(int)
    h, w, _ = a.shape
    bords = [(y, x) for y in range(h) for x in (0, w - 1)] + [(y, x) for x in range(w) for y in (0, h - 1)]
    fond = np.median(np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]]), axis=0)
    vide = _remplir(a, bords, np.abs(a - fond).sum(2) < 45)
    reste = ~vide
    ys, xs = np.where(reste)
    if len(ys):
        y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
        contour = np.concatenate([a[y0, x0:x1 + 1], a[y1, x0:x1 + 1], a[y0:y1 + 1, x0], a[y0:y1 + 1, x1]])
        tuile = np.median(contour, axis=0)
        # une tuile : bord du reste presque uni et assez grand
        if np.abs(contour - tuile).sum(1).mean() < 25 and (y1 - y0) * (x1 - x0) > 0.2 * h * w:
            graines = [(y, x) for y in range(y0, y1 + 1) for x in (x0, x1)] + \
                      [(y, x) for x in range(x0, x1 + 1) for y in (y0, y1)]
            vide |= _remplir(a, graines, reste & (np.abs(a - tuile).sum(2) < 40))
    alpha = (~vide).astype(np.uint8) * 255
    return Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), "RGBA")


def icone(cellule):
    d = detourer(cellule)
    boite = d.getchannel("A").getbbox()
    if not boite:
        return Image.new("RGBA", (TAILLE, TAILLE))
    d = d.crop(boite)
    cible = TAILLE - 2  # 1 px de marge pour le contour
    f = cible / max(d.width, d.height)
    w, h = max(1, round(d.width * f)), max(1, round(d.height * f))
    rgb = d.convert("RGB").resize((w, h), Image.BOX)
    a = d.getchannel("A").resize((w, h), Image.BOX)
    petit = Image.merge("RGBA", (*rgb.split(), a.point(lambda v: 255 if v > 120 else 0)))
    out = Image.new("RGBA", (TAILLE, TAILLE), (0, 0, 0, 0))
    out.paste(petit, ((TAILLE - w) // 2, (TAILLE - h) // 2))
    return out


def decouper(chemin, lignes, colonnes):
    """Découpe la zone occupée (pas toute l'image : le modèle laisse parfois
    une grande marge vide) en lignes × colonnes cellules égales."""
    img = Image.open(chemin).convert("RGB")
    a = np.asarray(img).astype(int)
    fond = np.median(np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]]), axis=0)
    occupe = np.abs(a - fond).sum(2) > 40
    ys, xs = np.where(occupe)
    marge = 12
    x0, y0 = max(0, xs.min() - marge), max(0, ys.min() - marge)
    x1, y1 = min(img.width, xs.max() + marge), min(img.height, ys.max() + marge)
    cw, ch = (x1 - x0) / colonnes, (y1 - y0) / lignes
    return [img.crop((int(x0 + c * cw), int(y0 + l * ch), int(x0 + (c + 1) * cw), int(y0 + (l + 1) * ch)))
            for l in range(lignes) for c in range(colonnes)]


if __name__ == "__main__":
    planche, grille, noms, dossier = sys.argv[1:5]
    l, c = (int(v) for v in grille.split("x"))
    noms = noms.split(",")
    cellules = decouper(planche, l, c)
    for nom, cel in zip(noms, cellules):
        if nom:
            icone(cel).save(f"{dossier.rstrip('/')}/{nom}.png", optimize=True)
    print(f"{len([n for n in noms if n])} icônes -> {dossier}")
