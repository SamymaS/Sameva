"""Importe les planches pixel art générées dans Figma vers les assets de l'app.

Source de vérité : le fichier Figma « Sameva · Pixel art »
(https://www.figma.com/design/JPJpwdPnsvXuE5n4D38SIP). Exporter chaque planche
en PNG (nœuds listés dans PLANCHES) dans un dossier, puis :

    python3 tools/pixel/importer_figma.py <dossier_des_planches>

Sorties : assets/sprites/chat_<race>.png (6 images 96 px), mougibot.png
(5 images 96 px), objets/<nom>.png (32 px), animations.json ; assets/sfx/*.wav.
"""
import json, os, subprocess, sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)
import depuis_concept as dc  # noqa: E402
import icones_depuis_planche as ip  # noqa: E402

RACINE = os.path.abspath(os.path.join(ICI, "..", ".."))
SPRITES = os.path.join(RACINE, "assets", "sprites")
SFX = os.path.join(RACINE, "assets", "sfx")

# fichier PNG attendu -> nœud Figma d'origine
PLANCHES = {
    "race_michi.png": "2:2", "race_lune.png": "2:3", "race_braise.png": "2:4",
    "race_neige.png": "2:5", "race_cosmos.png": "2:6", "race_sakura.png": "2:7",
    "mougibot_concept.png": "1:3",
    "objets_A.png": "1:4", "objets_B.png": "1:5", "objets_C.png": "1:6",
    "objets_D.png": "1:7", "objets_E.png": "1:8",
}

OBJETS = {
    "objets_A.png": ("2x5", "sword_rusty,sword_hunter,sword_legendary,armor_tunic,armor_mail,"
                            "armor_epic,helmet_hat,helmet_sage,ring_bronze,ring_mystic"),
    "objets_B.png": ("2x5", "boots_worn,boots_merc,potion_heal,potion_xp,potion_gold,"
                            "material_crystal,material_essence,material_stone,shoes_brown,shoes_tan"),
    "objets_C.png": ("2x5", "aura_fire,aura_gold,aura_holy,aura_shadow,aura_teal,"
                            "hat_bandana_orange,hat_bandana_teal,hat_beanie_red,hat_beanie_violet,hat_cone_blue"),
    "objets_D.png": ("2x5", "hat_cone_violet,hat_crown_cyan,hat_crown_gold,outfit_gold,outfit_navy,"
                            "outfit_red,outfit_teal,outfit_violet,pants_dark,pants_gold"),
    "objets_E.png": ("2x3", "pants_navy,pants_purple,pants_red,shoes_cyan,shoes_gold,shoes_mythic"),
}

RACES = ["michi", "lune", "braise", "neige", "cosmos", "sakura"]

# Images des feuilles de chat : 0 repos, 1 clignement, 2 content, 3 endormi, 4 triste, 5 excité.
# MougiBot : 0 repos, 1 observe, 2-3 accepte, 4 refuse.
MANIFESTE = {
    "chat": {
        "taille": 96,
        "repos": {"images": [0, 1, 0, 1, 0], "durees_ms": [2600, 140, 180, 140, 1800]},
        "content": {"images": [2], "durees_ms": [1000]},
        "excite": {"images": [5, 2], "durees_ms": [320, 320]},
        "triste": {"images": [4], "durees_ms": [1000]},
        "endormi": {"images": [3], "durees_ms": [1000]},
    },
    "mougibot": {
        "taille": 96,
        "repos": {"images": [0], "durees_ms": [1000]},
        "observe": {"images": [1], "durees_ms": [1000]},
        "accepte": {"images": [2, 3], "durees_ms": [380, 380]},
        "refuse": {"images": [4], "durees_ms": [1000]},
    },
    # chapeau du chat (cosmétique) -> icône d'objet posée sur la tête
    "chapeaux": {"wizard_hat": "helmet_hat", "crown": "hat_crown_gold", "party_hat": "hat_cone_blue",
                 "santa_hat": "hat_beanie_red", "bow": "hat_bandana_teal"},
}


def main(dossier):
    os.makedirs(os.path.join(SPRITES, "objets"), exist_ok=True)
    for race in RACES:
        dc.convertir_grille(os.path.join(dossier, f"race_{race}.png"), 2, 3, 96).save(
            os.path.join(SPRITES, f"chat_{race}.png"), optimize=True)
    feuille, n = dc.convertir(os.path.join(dossier, "mougibot_concept.png"), 96, couleurs=128)
    assert n == 5, n
    feuille.save(os.path.join(SPRITES, "mougibot.png"), optimize=True)
    for planche, (grille, noms) in OBJETS.items():
        l, c = (int(v) for v in grille.split("x"))
        for nom, cel in zip(noms.split(","), ip.decouper(os.path.join(dossier, planche), l, c)):
            ip.icone(cel).save(os.path.join(SPRITES, "objets", nom + ".png"), optimize=True)
    with open(os.path.join(SPRITES, "animations.json"), "w") as f:
        json.dump(MANIFESTE, f, indent=1, ensure_ascii=False)
    subprocess.run([sys.executable, os.path.join(ICI, "sfx.py"), SFX], check=True, stdout=subprocess.DEVNULL)
    print("assets importés depuis", dossier)


if __name__ == "__main__":
    main(sys.argv[1])
