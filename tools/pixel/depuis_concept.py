"""Transforme une planche de concepts (générée dans Figma, fond uni) en vraies
feuilles de sprites pixel art : découpe des images, réduction sur une grille
fixe, palette commune, fond transparent.

    python3 tools/pixel/depuis_concept.py planche.png sortie.png --taille 64 \
        --cadres "x0,y0,x1,y1;..."   (sinon détection automatique en colonnes)
"""
import argparse
import numpy as np
from PIL import Image


def groupes(idx, ecart):
    g = [[idx[0], idx[0]]]
    for i in idx[1:]:
        if i - g[-1][1] > ecart:
            g.append([i, i])
        else:
            g[-1][1] = i
    return g


def cadres_auto(rgb, fond, ecart=25):
    masque = np.abs(rgb - fond).sum(2) > 40
    lignes = np.where(masque.any(1))[0]
    cadres = []
    for y0, y1 in groupes(lignes, ecart):
        bande = masque[y0:y1 + 1]
        cols = np.where(bande.any(0))[0]
        for x0, x1 in groupes(cols, ecart):
            cadres.append((x0, y0, x1, y1))
    return cadres


def convertir(chemin, taille, cadres=None, couleurs=40, marge=0.06):
    img = Image.open(chemin).convert("RGB")
    rgb = np.asarray(img).astype(int)
    fond = np.median(rgb.reshape(-1, 3), axis=0)
    # marge de fond autour de la planche : un cadre près du bord reste propre
    bord = 400
    grand = Image.new("RGB", (img.width + 2 * bord, img.height + 2 * bord), tuple(int(v) for v in fond))
    grand.paste(img, (bord, bord))
    cadres = cadres or cadres_auto(rgb, fond)
    # un carré commun à toutes les images (même échelle partout)
    cote = int(max(max(x1 - x0, y1 - y0) for x0, y0, x1, y1 in cadres) * (1 + 2 * marge))
    images = []
    for x0, y0, x1, y1 in cadres:
        cx = (x0 + x1) // 2
        bas = y1 + int(cote * marge)  # personnages posés sur la même ligne de sol
        boite = (cx - cote // 2, bas - cote, cx - cote // 2 + cote, bas)
        crop = grand.crop(tuple(v + bord for v in boite))
        a = np.asarray(crop).astype(int)
        alpha = (np.abs(a - fond).sum(2) > 48).astype(np.uint8) * 255
        rgba = Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), "RGBA")
        petit_rgb = crop.resize((taille, taille), Image.BOX)
        petit_a = Image.fromarray(alpha).resize((taille, taille), Image.BOX)
        p = np.dstack([np.asarray(petit_rgb), (np.asarray(petit_a) > 110).astype(np.uint8) * 255])
        images.append(Image.fromarray(p.astype(np.uint8), "RGBA"))
    # palette commune à toutes les images (cohérence entre les cadres)
    feuille = Image.new("RGBA", (taille * len(images), taille), (0, 0, 0, 0))
    for i, im in enumerate(images):
        feuille.paste(im, (i * taille, 0))
    arr = np.asarray(feuille)
    a = arr[..., 3]
    # palette apprise sur les seuls pixels opaques (le fond ne l'écrase pas)
    opaques = arr[a > 0][:, :3]
    echantillon = Image.fromarray(opaques.reshape(1, -1, 3).astype(np.uint8), "RGB")
    pal = echantillon.quantize(colors=couleurs, method=Image.MEDIANCUT)
    q = Image.fromarray(arr[..., :3].astype(np.uint8), "RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    sortie = np.dstack([np.asarray(q), a])
    sortie[a == 0] = 0
    return Image.fromarray(sortie.astype(np.uint8), "RGBA"), len(images)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("planche")
    ap.add_argument("sortie")
    ap.add_argument("--taille", type=int, default=64)
    ap.add_argument("--couleurs", type=int, default=40)
    ap.add_argument("--cadres", default="")
    ns = ap.parse_args()
    cadres = [tuple(int(v) for v in c.split(",")) for c in ns.cadres.split(";")] if ns.cadres else None
    feuille, n = convertir(ns.planche, ns.taille, cadres, ns.couleurs)
    feuille.save(ns.sortie, optimize=True)
    print(f"{n} images de {ns.taille} px -> {ns.sortie}")


def convertir_grille(chemin, lignes, colonnes, taille, couleurs=128, marge=0.08):
    """Planche en grille (lignes × colonnes) : chaque cellule est détourée, puis
    toutes sont mises à la même échelle et posées sur la même ligne de sol."""
    import icones_depuis_planche as ip
    cellules = [ip.detourer(c) for c in ip.decouper(chemin, lignes, colonnes)]
    boites = [c.getchannel("A").getbbox() for c in cellules]
    cote = int(max(max(b[2] - b[0], b[3] - b[1]) for b in boites) * (1 + 2 * marge))
    images = []
    for c, (x0, y0, x1, y1) in zip(cellules, boites):
        cx = (x0 + x1) // 2
        bas = y1 + int(cote * marge)
        carre = Image.new("RGBA", (cote, cote), (0, 0, 0, 0))
        carre.paste(c.crop((cx - cote // 2, bas - cote, cx - cote // 2 + cote, bas)), (0, 0))
        rgb = carre.convert("RGB").resize((taille, taille), Image.BOX)
        a = carre.getchannel("A").resize((taille, taille), Image.BOX).point(lambda v: 255 if v > 110 else 0)
        images.append(Image.merge("RGBA", (*rgb.split(), a)))
    feuille = Image.new("RGBA", (taille * len(images), taille), (0, 0, 0, 0))
    for i, im in enumerate(images):
        feuille.paste(im, (i * taille, 0))
    arr = np.asarray(feuille)
    a = arr[..., 3]
    opaques = arr[a > 0][:, :3]
    pal = Image.fromarray(opaques.reshape(1, -1, 3).astype(np.uint8), "RGB").quantize(colors=couleurs, method=Image.MEDIANCUT)
    q = Image.fromarray(arr[..., :3].astype(np.uint8), "RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    sortie = np.dstack([np.asarray(q), a])
    sortie[a == 0] = 0
    return Image.fromarray(sortie.astype(np.uint8), "RGBA")
