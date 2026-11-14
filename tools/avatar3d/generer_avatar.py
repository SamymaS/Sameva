"""Avatar 2.5D de Sameva : modèle 3D en pièces, rendu en couches sous 8 angles.

Lancement (Blender 5.x, ou le module Python `bpy`) :
    blender -b -P tools/avatar3d/generer_avatar.py -- [--sortie assets/avatar] [--blend avatar.blend]
            [--apercu] [--echantillons 48]

Chaque pièce (corps, haut, bas, chaussures, visage, sourcils, coiffures,
chapeaux) est rendue **seule**, en blanc, les autres pièces la masquant comme
dans la réalité (« holdout »). L'application empile les couches et les teinte
(couleur de peau, de cheveux, des cosmétiques) : une seule série d'images
couvre toutes les combinaisons. Une feuille par couche : 8 angles côte à côte.
"""
import json
import math
import os
import sys

import bpy  # avant bmesh et mathutils : le module bpy les installe
import bmesh
from mathutils import Matrix, Vector

LARGEUR, HAUTEUR = 400, 800
ANGLES = 8
SILHOUETTES = {
    # épaules, taille, hanches (demi-largeurs), poitrine (profondeur ajoutée)
    "male": dict(epaule=0.178, taille=0.128, hanche=0.132, poitrine=0.0),
    "female": dict(epaule=0.15, taille=0.104, hanche=0.146, poitrine=0.026),
}
COIFFURES = ["short", "medium", "long", "ponytail", "bun", "spiky"]
COIFFURES_LONGUES = ("cheveux_long", "cheveux_ponytail")
CHAPEAUX = {1: "cone", 2: "couronne", 3: "bonnet", 4: "bandana"}
TETE = Vector((0, 0, 1.555))
# Proportions adultes réalistes : environ sept têtes et demie de haut. La tête
# est modelée en grand (plus de détail au maillage) puis réduite autour du cou.
COU = Vector((0, 0, 1.43))
TASSEMENT, GROSSEUR_TETE, CARRURE = 1.0, 0.7, 1.0
# Cadre de la tête dans l'image (gauche, haut, largeur, hauteur, en fractions) : vignettes et profil.
BUSTE = (0.26, 0.1, 0.48, 0.24)


# ── Outils de modelage ───────────────────────────────────────────────────────

def ellipsoide(bm, centre, echelle, rot=(0, 0, 0)):
    m = (Matrix.Translation(centre) @ Matrix.Rotation(rot[2], 4, "Z") @ Matrix.Rotation(rot[1], 4, "Y")
         @ Matrix.Rotation(rot[0], 4, "X") @ Matrix.Diagonal((*echelle, 1)))
    bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=20, radius=1.0, matrix=m)


def capsule(bm, a, b, ra, rb):
    a, b = Vector(a), Vector(b)
    axe = b - a
    quat = Vector((0, 0, 1)).rotation_difference(axe.normalized())
    m = Matrix.Translation((a + b) / 2) @ quat.to_matrix().to_4x4()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=28, radius1=ra, radius2=rb, depth=axe.length, matrix=m)
    ellipsoide(bm, a, (ra, ra, ra))
    ellipsoide(bm, b, (rb, rb, rb))


def cone(bm, base, sommet, rayon, rayon_haut=0.0):
    base, sommet = Vector(base), Vector(sommet)
    axe = sommet - base
    quat = Vector((0, 0, 1)).rotation_difference(axe.normalized())
    m = Matrix.Translation((base + sommet) / 2) @ quat.to_matrix().to_4x4()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=32, radius1=rayon, radius2=rayon_haut, depth=axe.length, matrix=m)


def tore(bm, centre, rayon, epaisseur, aplati=1.0, incline=0.0):
    seg, sec = 40, 12
    verts = []
    rot = Matrix.Rotation(incline, 4, "X")
    for i in range(seg):
        t = 2 * math.pi * i / seg
        rang = []
        for j in range(sec):
            p = 2 * math.pi * j / sec
            v = Vector(((rayon + epaisseur * math.cos(p)) * math.cos(t),
                        (rayon + epaisseur * math.cos(p)) * math.sin(t),
                        epaisseur * aplati * math.sin(p)))
            rang.append(bm.verts.new(rot @ v + Vector(centre)))
        verts.append(rang)
    for i in range(seg):
        for j in range(sec):
            bm.faces.new((verts[i][j], verts[(i + 1) % seg][j], verts[(i + 1) % seg][(j + 1) % sec], verts[i][(j + 1) % sec]))


def couper(bm, point, normale):
    """Supprime tout ce qui est du côté de la normale, et referme la coupe."""
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=point, plane_no=normale, clear_outer=True)
    aretes = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
    if aretes:
        bmesh.ops.holes_fill(bm, edges=aretes)


def objet(nom, construire, voxel=0.011, lissage=6, fondre=True):
    bm = bmesh.new()
    construire(bm)
    mesh = bpy.data.meshes.new(nom)
    bm.to_mesh(mesh)
    bm.free()
    ob = bpy.data.objects.new(nom, mesh)
    bpy.context.scene.collection.objects.link(ob)
    if fondre:
        r = ob.modifiers.new("fusion", "REMESH")
        r.mode, r.voxel_size, r.use_smooth_shade = "VOXEL", voxel, True
        s = ob.modifiers.new("lissage", "SMOOTH")
        s.factor, s.iterations = 0.6, lissage
        with bpy.context.temp_override(object=ob, active_object=ob, selected_objects=[ob]):
            bpy.ops.object.modifier_apply(modifier="fusion")
            bpy.ops.object.modifier_apply(modifier="lissage")
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


# ── Pièces ───────────────────────────────────────────────────────────────────

def membres(s, gonfle=0.0, mains=True, jambes=True, bras=True, jusquau_poignet=True):
    """Renvoie une fonction qui dessine bras et jambes (gonflés pour les vêtements)."""
    ep = s["epaule"]

    def f(bm):
        for c in (-1, 1):
            if bras:
                epaule, coude = (c * (ep + 0.006), 0, 1.29), (c * (ep + 0.04), 0.008, 1.04)
                poignet = (c * (ep + 0.05), -0.022, 0.81)
                capsule(bm, epaule, coude, 0.044 + gonfle, 0.038 + gonfle)
                capsule(bm, coude, poignet, 0.038 + gonfle, 0.029 + gonfle * (1.2 if jusquau_poignet else 1))
                if mains:
                    ellipsoide(bm, (c * (ep + 0.053), -0.027, 0.765), (0.017, 0.034, 0.045))  # paume
                    ellipsoide(bm, (c * (ep + 0.051), -0.031, 0.712), (0.014, 0.03, 0.04))  # doigts
                    capsule(bm, (c * (ep + 0.048), -0.052, 0.772), (c * (ep + 0.045), -0.062, 0.73), 0.011, 0.009)  # pouce
            if jambes:
                hanche, genou, cheville = (c * 0.074, 0, 0.86), (c * 0.08, -0.005, 0.48), (c * 0.082, 0.005, 0.09)
                capsule(bm, hanche, genou, 0.072 + gonfle, 0.05 + gonfle)
                capsule(bm, genou, cheville, 0.05 + gonfle, 0.036 + gonfle)
                ellipsoide(bm, (c * 0.082, 0.02, 0.34), (0.044 + gonfle, 0.05 + gonfle, 0.1))  # mollet
    return f


def tronc(bm, s, gonfle=0.0):
    g = 1 + gonfle * 5
    ellipsoide(bm, (0, 0, 0.90), (s["hanche"] * g, 0.098 * g, 0.125))
    ellipsoide(bm, (0, 0, 1.04), (s["taille"] * g, 0.086 * g, 0.15))
    ellipsoide(bm, (0, -0.004, 1.2), (s["epaule"] * 0.9 * g, (0.098 + s["poitrine"] * 0.4) * g, 0.155))
    if s["poitrine"]:
        ellipsoide(bm, (0, -0.062, 1.205), (0.1 * g, 0.048 * g + s["poitrine"], 0.055 * g))
    else:
        ellipsoide(bm, (0, -0.04, 1.225), (0.135 * g, 0.062 * g, 0.07 * g))  # pectoraux
    for c in (-1, 1):
        ellipsoide(bm, (c * s["epaule"] * 0.95, 0, 1.305), (0.044 * g, 0.05 * g, 0.044 * g))
        # Pente du cou vers l'épaule (trapèze) : évite l'épaule « en boule ».
        capsule(bm, (c * 0.035, 0.012, 1.365), (c * s["epaule"] * 0.9, 0.004, 1.318), 0.034 + gonfle, 0.04 + gonfle)


def corps(s):
    def f(bm):
        tronc(bm, s)
        membres(s)(bm)
        capsule(bm, (0, 0.008, 1.33), (0, 0.0, 1.47), 0.054, 0.046)
        for c in (-1, 1):
            ellipsoide(bm, (c * 0.082, -0.035, 0.04), (0.04, 0.09, 0.04))  # pieds
    return f


def tete(bm):
    ellipsoide(bm, TETE + Vector((0, 0.012, 0.02)), (0.152, 0.178, 0.16))  # crâne
    ellipsoide(bm, TETE + Vector((0, -0.02, -0.07)), (0.128, 0.142, 0.13))  # joues
    ellipsoide(bm, TETE + Vector((0, -0.062, -0.165)), (0.07, 0.078, 0.062))  # menton
    capsule(bm, TETE + Vector((0, -0.158, 0.012)), TETE + Vector((0, -0.182, -0.062)), 0.014, 0.019)  # arête du nez
    for c in (-1, 1):
        ellipsoide(bm, TETE + Vector((c * 0.02, -0.168, -0.072)), (0.016, 0.02, 0.014))  # narines
        ellipsoide(bm, TETE + Vector((c * 0.152, 0.018, -0.03)), (0.016, 0.034, 0.052))  # oreilles
        ellipsoide(bm, TETE + Vector((c * 0.062, -0.126, 0.058)), (0.05, 0.03, 0.02))  # arcades


def haut(s):
    def f(bm):
        tronc(bm, s, gonfle=0.012)
        capsule(bm, (-0.085, 0.01, 1.32), (0.085, 0.01, 1.32), 0.042, 0.042)  # épaules du vêtement
        membres(s, gonfle=0.009, mains=False, jambes=False)(bm)
        tore(bm, (0, 0.004, 1.375), 0.06, 0.016, aplati=0.9, incline=0.12)  # col
        ellipsoide(bm, (0, 0.085, 1.335), (0.1, 0.05, 0.06))  # capuche repliée
        couper(bm, (0, 0, 0.865), (0, 0, -1))  # ourlet
    return f


def bas(s):
    def f(bm):
        ellipsoide(bm, (0, 0, 0.9), (s["hanche"] * 1.07, 0.106, 0.128))
        membres(s, gonfle=0.01, bras=False)(bm)
        couper(bm, (0, 0, 0.105), (0, 0, -1))
        couper(bm, (0, 0, 1.0), (0, 0, 1))
    return f


def chaussures(bm):
    for c in (-1, 1):
        ellipsoide(bm, (c * 0.082, -0.055, 0.045), (0.046, 0.12, 0.045))
        ellipsoide(bm, (c * 0.082, 0.01, 0.075), (0.044, 0.06, 0.058))
    couper(bm, (0, 0, 0.004), (0, 0, -1))


def calotte(bm, bas_nuque, frange=0.0, volume=1.0):
    """Chevelure de base : enveloppe du crâne, visage dégagé, coupée à la nuque."""
    ellipsoide(bm, TETE + Vector((0, 0.014, 0.014)), (0.172 * volume, 0.182 * volume, 0.19 * volume))
    if frange:
        ellipsoide(bm, TETE + Vector((0.02, -0.135, 0.125)), (0.125, 0.06, 0.05 + frange), rot=(0.25, 0.12, 0))
    # Dégage le visage : plan incliné du front vers les oreilles.
    couper(bm, TETE + Vector((0, -0.062, 0.062 - frange * 0.3)), Vector((0, -0.74, -0.67)))
    couper(bm, (0, 0, bas_nuque), (0, 0, -1))


def coiffure(nom):
    def f(bm):
        if nom == "short":
            calotte(bm, TETE.z - 0.07, frange=0.012)
        elif nom == "medium":
            calotte(bm, TETE.z - 0.145, frange=0.03, volume=1.03)
        elif nom == "long":
            calotte(bm, TETE.z - 0.13, frange=0.03, volume=1.03)
            ellipsoide(bm, (0, 0.105, 1.3), (0.165, 0.075, 0.26))
            for c in (-1, 1):
                ellipsoide(bm, (c * 0.14, 0.03, 1.36), (0.05, 0.07, 0.2))
        elif nom == "ponytail":
            calotte(bm, TETE.z - 0.07, frange=0.02)
            capsule(bm, TETE + Vector((0, 0.17, 0.07)), (0, 0.27, 1.36), 0.06, 0.03)
            tore(bm, TETE + Vector((0, 0.165, 0.075)), 0.045, 0.02, incline=1.1)
        elif nom == "bun":
            calotte(bm, TETE.z - 0.075, frange=0.015)
            ellipsoide(bm, TETE + Vector((0, 0.05, 0.215)), (0.085, 0.085, 0.075))
        elif nom == "spiky":
            calotte(bm, TETE.z - 0.06)
            for x, y, h, inc in [(-0.09, -0.05, 0.11, -0.5), (0, -0.07, 0.13, 0), (0.09, -0.05, 0.11, 0.5),
                                 (-0.11, 0.05, 0.1, -0.7), (0.11, 0.05, 0.1, 0.7), (-0.045, 0.02, 0.14, -0.2),
                                 (0.05, 0.03, 0.14, 0.25), (0, 0.11, 0.11, 0)]:
                base = TETE + Vector((x, y, 0.14))
                cone(bm, base, base + Vector((math.sin(inc) * h, y * 0.6, h)), 0.055)
    return f


def sourcils(bm):
    for c in (-1, 1):
        capsule(bm, TETE + Vector((c * 0.026, -0.158, 0.04)), TETE + Vector((c * 0.092, -0.142, 0.046)), 0.0075, 0.0045)


def chapeau(style):
    def f(bm):
        haut_crane = TETE + Vector((0, 0.01, 0.0))
        if style == 1:  # chapeau conique à large bord
            cone(bm, haut_crane + Vector((0, 0, 0.115)), haut_crane + Vector((0.02, 0.05, 0.47)), 0.15)
            ellipsoide(bm, haut_crane + Vector((0, 0, 0.115)), (0.3, 0.3, 0.018))
        elif style == 2:  # couronne
            tore(bm, haut_crane + Vector((0, 0, 0.165)), 0.118, 0.022, aplati=1.6)
            for i in range(7):
                a = 2 * math.pi * i / 7
                b = haut_crane + Vector((0.118 * math.sin(a), -0.118 * math.cos(a), 0.17))
                cone(bm, b, b + Vector((0, 0, 0.085)), 0.03)
        elif style == 3:  # bonnet
            ellipsoide(bm, haut_crane + Vector((0, 0.008, 0.03)), (0.185, 0.195, 0.2))
            couper(bm, haut_crane + Vector((0, 0, 0.075)), Vector((0, -0.16, -1)))
            tore(bm, haut_crane + Vector((0, 0.006, 0.082)), 0.168, 0.03, aplati=1.1, incline=-0.16)
            ellipsoide(bm, haut_crane + Vector((0, 0.01, 0.25)), (0.045, 0.045, 0.045))
        else:  # bandana
            tore(bm, haut_crane + Vector((0, 0.008, 0.085)), 0.166, 0.026, aplati=1.5, incline=-0.16)
            for c in (-1, 1):
                capsule(bm, haut_crane + Vector((0, 0.185, 0.06)), haut_crane + Vector((c * 0.06, 0.24, -0.03)), 0.022, 0.012)
    return f


def visage():
    """Yeux et lèvres : couleurs propres, non teintées par l'application."""
    obs = []
    for c in (-1, 1):
        centre = TETE + Vector((c * 0.058, -0.136, 0.0))
        obs.append(("blanc", objet("oeil_blanc", lambda bm, p=centre: ellipsoide(bm, p, (0.034, 0.016, 0.021)), fondre=False)))
        obs.append(("iris", objet("oeil_iris", lambda bm, p=centre: ellipsoide(bm, p + Vector((0, -0.0095, 0.0005)), (0.017, 0.008, 0.019)), fondre=False)))
        obs.append(("pupille", objet("oeil_pupille", lambda bm, p=centre: ellipsoide(bm, p + Vector((0, -0.0135, 0.0005)), (0.008, 0.005, 0.009)), fondre=False)))
        obs.append(("blanc", objet("oeil_reflet", lambda bm, p=centre: ellipsoide(bm, p + Vector((0.005, -0.017, 0.005)), (0.004, 0.002, 0.004)), fondre=False)))
        # Paupière supérieure : un trait sombre qui donne le regard.
        obs.append(("cils", objet("cils", lambda bm, p=centre, c=c: capsule(bm, p + Vector((-c * 0.031, -0.004, 0.019)), p + Vector((c * 0.035, 0.004, 0.017)), 0.0045, 0.0035), fondre=False)))
    obs.append(("levres", objet("levre_haut", lambda bm: ellipsoide(bm, TETE + Vector((0, -0.147, -0.108)), (0.04, 0.014, 0.0085)), fondre=False)))
    obs.append(("levres", objet("levre_bas", lambda bm: ellipsoide(bm, TETE + Vector((0, -0.146, -0.121)), (0.033, 0.014, 0.0095)), fondre=False)))
    return obs


# ── Scène ────────────────────────────────────────────────────────────────────

def matiere(nom, couleur, rugosite=0.75):
    m = bpy.data.materials.new(nom)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*couleur, 1)
    b.inputs["Roughness"].default_value = rugosite
    return m


def preparer_scene(echantillons):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = echantillons
    sc.cycles.use_denoising = False
    sc.cycles.pixel_filter_type, sc.cycles.filter_width = "BLACKMAN_HARRIS", 1.6
    sc.cycles.max_bounces = 3
    sc.render.film_transparent = True
    sc.render.resolution_x, sc.render.resolution_y = LARGEUR, HAUTEUR
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    monde = bpy.data.worlds.new("monde")
    monde.use_nodes = True
    fond = monde.node_tree.nodes["Background"]
    fond.inputs[0].default_value = (1, 1, 1, 1)
    fond.inputs[1].default_value = 0.62
    sc.world = monde

    cam_d = bpy.data.cameras.new("camera")
    cam_d.type, cam_d.ortho_scale = "ORTHO", 2.1
    cam = bpy.data.objects.new("camera", cam_d)
    sc.collection.objects.link(cam)
    # Vue légèrement plongeante, comme dans un jeu en 2.5D.
    plongee = math.radians(9)
    cible = Vector((0, 0, 0.96))
    cam.location = cible + Vector((0, -6 * math.cos(plongee), 6 * math.sin(plongee)))
    cam.rotation_euler = (math.radians(90) - plongee, 0, 0)
    sc.camera = cam

    def soleil(nom, force, rot, taille=0.3):
        d = bpy.data.lights.new(nom, "SUN")
        d.energy, d.angle = force, taille
        o = bpy.data.objects.new(nom, d)
        o.rotation_euler = [math.radians(a) for a in rot]
        sc.collection.objects.link(o)

    soleil("principale", 2.6, (52, 0, -38))
    soleil("contre", 1.1, (115, 0, 150), taille=0.6)
    return sc


def construire():
    blanc = matiere("teinte", (0.86, 0.86, 0.86))
    pivot = bpy.data.objects.new("pivot", None)
    bpy.context.scene.collection.objects.link(pivot)
    couches = {}

    m_corps = Matrix.Diagonal((CARRURE, 1.02, TASSEMENT, 1))
    m_tete = (Matrix.Translation((0, 0, COU.z * TASSEMENT - COU.z)) @ Matrix.Translation(COU)
              @ Matrix.Diagonal((GROSSEUR_TETE,) * 3 + (1,)) @ Matrix.Translation(-COU))

    def ajouter(nom, obs, de_la_tete=False):
        obs = obs if isinstance(obs, list) else [obs]
        for o in obs:
            o.parent = pivot
            o.matrix_local = m_tete if (de_la_tete or o.name.startswith("tete")) else m_corps
            if not o.data.materials:
                o.data.materials.append(blanc)
        couches[nom] = obs

    for cle, s in SILHOUETTES.items():
        ajouter(f"corps_{cle}", [objet(f"corps_{cle}", corps(s)), objet("tete", tete, voxel=0.008)])
        ajouter(f"haut_{cle}", objet(f"haut_{cle}", haut(s)))
        ajouter(f"bas_{cle}", objet(f"bas_{cle}", bas(s)))
    ajouter("chaussures", objet("chaussures", chaussures))
    for c in COIFFURES:
        ajouter(f"cheveux_{c}", objet(f"cheveux_{c}", coiffure(c), voxel=0.008, lissage=5), de_la_tete=True)
    ajouter("sourcils", objet("sourcils", sourcils, fondre=False), de_la_tete=True)
    for style, nom in CHAPEAUX.items():
        ajouter(f"chapeau_{style}", objet(f"chapeau_{nom}", chapeau(style), voxel=0.008, lissage=3), de_la_tete=True)
    mats = {"blanc": matiere("oeil_blanc", (0.95, 0.95, 0.95), 0.3), "iris": matiere("iris", (0.16, 0.085, 0.04), 0.25),
            "pupille": matiere("pupille", (0.01, 0.01, 0.01), 0.2), "cils": matiere("cils", (0.03, 0.02, 0.02), 0.6),
            "levres": matiere("levres", (0.52, 0.24, 0.22), 0.5)}
    yeux = []
    for role, o in visage():
        o.data.materials.append(mats[role])
        yeux.append(o)
    ajouter("visage", yeux, de_la_tete=True)
    return pivot, couches


def toujours_presentes(silhouette):
    return [f"corps_{silhouette}", f"haut_{silhouette}", f"bas_{silhouette}", "chaussures"]


def rendre(sc, pivot, couches, sortie, angles):
    """Une feuille par couche : les angles côte à côte, de face puis en tournant vers la gauche."""
    import numpy as np
    os.makedirs(sortie, exist_ok=True)
    tmp = os.path.join(sortie, "_tmp.png")
    manifeste = {"largeur": LARGEUR, "hauteur": HAUTEUR, "angles": len(angles), "buste": list(BUSTE), "couches": {}}

    def rendu(visible, masques, sortie_nom=None):
        for nom, obs in couches.items():
            for o in obs:
                o.hide_render = not (nom == visible or nom in masques)
                o.is_holdout = nom != visible
        feuille = np.zeros((HAUTEUR, LARGEUR * len(angles), 4), dtype=np.float32)
        for i, a in enumerate(angles):
            pivot.rotation_euler = (0, 0, math.radians(a))
            sc.render.filepath = tmp
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(tmp)
            px = np.array(img.pixels[:], dtype=np.float32).reshape(HAUTEUR, LARGEUR, 4)
            bpy.data.images.remove(img)
            feuille[:, i * LARGEUR:(i + 1) * LARGEUR] = px
        out = bpy.data.images.new("feuille", LARGEUR * len(angles), HAUTEUR, alpha=True)
        out.pixels = feuille.ravel()
        cle = sortie_nom or visible
        out.filepath_raw, out.file_format = os.path.join(sortie, f"{cle}.png"), "PNG"
        out.save()
        bpy.data.images.remove(out)
        manifeste["couches"][cle] = f"{cle}.png"
        print("couche", cle, flush=True)

    for cle in SILHOUETTES:
        base = toujours_presentes(cle)
        for nom in base[:3]:
            rendu(nom, base)
    # Pièces communes aux deux silhouettes : masquées par la première.
    base = toujours_presentes("male")
    rendu("chaussures", base)
    for nom in couches:
        if nom in COIFFURES_LONGUES:
            # Elles descendent sur les épaules : un rendu par silhouette.
            for cle in SILHOUETTES:
                rendu(nom, toujours_presentes(cle), sortie_nom=f"{nom}_{cle}")
        elif nom.startswith(("cheveux_", "chapeau_")) or nom in ("visage", "sourcils"):
            rendu(nom, base)
    os.remove(tmp)
    compacter(sortie, [f for f in manifeste["couches"].values() if f != "visage.png"])
    with open(os.path.join(sortie, "manifeste.json"), "w", encoding="utf-8") as f:
        json.dump(manifeste, f, ensure_ascii=False, indent=1)


def compacter(sortie, fichiers):
    """Les couches teintées sont grises : gris + transparence suffit (fichiers 2 à 3 fois plus légers)."""
    try:
        from PIL import Image
    except ImportError:
        print("Pillow absent : feuilles laissées en RVBA (plus lourdes, même rendu).")
        return
    for f in fichiers:
        chemin = os.path.join(sortie, f)
        Image.open(chemin).convert("LA").save(chemin, optimize=True)
    visage = os.path.join(sortie, "visage.png")
    if os.path.exists(visage):
        Image.open(visage).save(visage, optimize=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

    def option(nom, defaut=None):
        return args[args.index(nom) + 1] if nom in args else defaut

    sc = preparer_scene(int(option("--echantillons", "48")))
    pivot, couches = construire()
    if option("--blend"):
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(option("--blend")))
    angles = [0, 45] if "--apercu" in args else [i * 360 / ANGLES for i in range(ANGLES)]
    rendre(sc, pivot, couches, os.path.abspath(option("--sortie", "assets/avatar")), angles)


if __name__ == "__main__":
    main()
