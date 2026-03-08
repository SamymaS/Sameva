#!/usr/bin/env python3
"""
Génère les assets SVG pixel art (style RPG) pour tous les items Sameva.
Usage : python scripts/generate_item_assets.py
Output: assets/items/*.svg
"""

import os

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'items')
os.makedirs(OUTPUT_DIR, exist_ok=True)

OUTLINE = '#1A1428'


# ─── Helpers ──────────────────────────────────────────────────────────────────

def darken(hex_c, amount=0.3):
    h = hex_c.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    r = max(0, int(r * (1 - amount)))
    g = max(0, int(g * (1 - amount)))
    b = max(0, int(b * (1 - amount)))
    return f'#{r:02X}{g:02X}{b:02X}'

def lighten(hex_c, amount=0.35):
    h = hex_c.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    r = min(255, int(r + (255 - r) * amount))
    g = min(255, int(g + (255 - g) * amount))
    b = min(255, int(b + (255 - b) * amount))
    return f'#{r:02X}{g:02X}{b:02X}'

def R(x, y, w, h, c, rx=0):
    if rx:
        return f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{c}"/>'
    return f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}"/>'

def Ci(cx, cy, r, c):
    return f'  <circle cx="{cx}" cy="{cy}" r="{r}" fill="{c}"/>'

def Poly(pts, c):
    p = ' '.join(f'{x},{y}' for x, y in pts)
    return f'  <polygon points="{p}" fill="{c}"/>'

def Path(d, c, sw=0, sc='none'):
    if sw:
        return f'  <path d="{d}" fill="{c}" stroke="{sc}" stroke-width="{sw}"/>'
    return f'  <path d="{d}" fill="{c}"/>'

def svg_wrap(parts, size=64):
    body = '\n'.join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'viewBox="0 0 {size} {size}" width="{size}" height="{size}">\n'
            f'{body}\n</svg>')

def save(filename, content):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'  ✓ {filename}')


# ─── SHAPE: SWORD ─────────────────────────────────────────────────────────────

def make_sword(blade, blade_hi=None, guard=None, guard_hi=None, handle='#6B3020', pommel=None, tip_gem=None):
    if guard is None:
        guard = '#C8962A'
    if pommel is None:
        pommel = darken(handle, 0.3)
    if blade_hi is None:
        blade_hi = lighten(blade, 0.4)
    if guard_hi is None:
        guard_hi = lighten(guard, 0.3)
    blade_sh = darken(blade, 0.25)
    guard_sh = darken(guard, 0.25)
    p = []
    # Blade outline shadow
    p.append(R(25, 1, 14, 31, OUTLINE))
    # Blade body
    p.append(R(27, 3, 10, 27, blade_sh))
    p.append(R(28, 3, 8, 25, blade))
    p.append(R(29, 3, 4, 23, blade_hi))
    # Blade tip (triangle)
    p.append(Poly([(27, 3), (37, 3), (32, -3)], blade))
    p.append(Poly([(29, 3), (35, 3), (32, 0)], blade_hi))
    # Guard outline
    p.append(R(9, 28, 46, 12, OUTLINE))
    # Guard body
    p.append(R(11, 30, 42, 8, guard_sh))
    p.append(R(13, 31, 38, 6, guard))
    p.append(R(15, 32, 20, 4, guard_hi))
    # Blade through guard
    p.append(R(27, 28, 10, 12, blade_sh))
    p.append(R(28, 28, 8, 12, blade))
    p.append(R(29, 28, 4, 12, blade_hi))
    # Guard gems (small circles on tips)
    if tip_gem:
        p.append(Ci(13, 34, 3, tip_gem))
        p.append(Ci(51, 34, 3, tip_gem))
    # Handle outline
    p.append(R(25, 40, 14, 22, OUTLINE))
    # Handle body
    p.append(R(27, 42, 10, 18, darken(handle, 0.2)))
    p.append(R(28, 42, 8, 18, handle))
    p.append(R(29, 42, 3, 16, lighten(handle, 0.2)))
    # Grip wraps
    wrap = darken(handle, 0.4)
    for yy in [45, 50, 55]:
        p.append(R(28, yy, 8, 2, wrap))
    # Pommel
    p.append(R(23, 60, 18, 6, OUTLINE))
    p.append(R(25, 61, 14, 4, pommel))
    p.append(R(27, 61, 6, 2, lighten(pommel, 0.3)))
    return svg_wrap(p)


# ─── SHAPE: ARMOR ─────────────────────────────────────────────────────────────

def make_armor(main, trim, detail=None, gem=None):
    if detail is None:
        detail = darken(main, 0.2)
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.3)
    trim_hi = lighten(trim, 0.3)
    p = []
    # Shoulder outlines
    p.append(R(2, 10, 18, 16, OUTLINE))
    p.append(R(44, 10, 18, 16, OUTLINE))
    # Shoulders
    p.append(R(4, 12, 14, 12, main_sh))
    p.append(R(5, 13, 12, 10, main))
    p.append(R(5, 13, 5, 8, main_hi))
    p.append(R(46, 12, 14, 12, main_sh))
    p.append(R(47, 13, 12, 10, main))
    p.append(R(52, 13, 5, 8, main_hi))
    # Shoulder trim
    p.append(R(4, 12, 14, 3, trim))
    p.append(R(46, 12, 14, 3, trim))
    # Chest outline
    p.append(R(14, 20, 36, 36, OUTLINE))
    # Chest body
    p.append(R(16, 22, 32, 32, main_sh))
    p.append(R(18, 23, 28, 30, main))
    p.append(R(20, 24, 12, 26, main_hi))
    # Chest vertical divider
    p.append(R(31, 23, 2, 30, detail))
    # Chest trim (bottom)
    p.append(R(16, 50, 32, 4, trim))
    p.append(R(18, 51, 28, 2, trim_hi))
    # Center gem
    if gem:
        p.append(Ci(32, 35, 5, OUTLINE))
        p.append(Ci(32, 35, 4, gem))
        p.append(Ci(31, 33, 1.5, lighten(gem, 0.5)))
    # Belt
    p.append(R(14, 54, 36, 8, OUTLINE))
    p.append(R(16, 55, 32, 6, darken(trim, 0.1)))
    p.append(R(29, 55, 6, 6, OUTLINE))
    p.append(R(30, 56, 4, 4, trim))
    return svg_wrap(p)


# ─── SHAPE: HELMET ────────────────────────────────────────────────────────────

def make_helmet(main, visor, trim, gem=None):
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.3)
    trim_hi = lighten(trim, 0.3)
    p = []
    # Dome outline
    p.append(R(10, 4, 44, 38, OUTLINE, rx=12))
    # Dome body
    p.append(R(12, 6, 40, 34, main_sh, rx=10))
    p.append(R(14, 8, 36, 30, main, rx=8))
    p.append(R(16, 10, 16, 20, main_hi))
    # Cheek guards
    p.append(R(8, 34, 12, 20, OUTLINE, rx=3))
    p.append(R(9, 35, 10, 18, main_sh, rx=2))
    p.append(R(10, 36, 8, 16, main, rx=2))
    p.append(R(44, 34, 12, 20, OUTLINE, rx=3))
    p.append(R(45, 35, 10, 18, main_sh, rx=2))
    p.append(R(46, 36, 8, 16, main, rx=2))
    # Visor slit
    p.append(R(16, 32, 32, 8, OUTLINE, rx=2))
    p.append(R(18, 33, 28, 6, visor, rx=2))
    p.append(R(20, 34, 8, 3, lighten(visor, 0.15)))
    # Top crest/trim
    p.append(R(26, 4, 12, 6, trim))
    p.append(R(28, 5, 8, 4, trim_hi))
    # Front plate trim
    p.append(R(14, 36, 36, 4, trim))
    if gem:
        p.append(Ci(32, 20, 5, OUTLINE))
        p.append(Ci(32, 20, 4, gem))
        p.append(Ci(31, 18, 1.5, lighten(gem, 0.5)))
    return svg_wrap(p)


# ─── SHAPE: BOOTS (side view) ─────────────────────────────────────────────────

def make_boots(main, sole, trim=None, buckle=None):
    if trim is None:
        trim = darken(main, 0.2)
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.3)
    sole_hi = lighten(sole, 0.25)
    p = []
    # ── Left boot ──
    # Shaft outline
    p.append(R(4, 10, 22, 34, OUTLINE, rx=4))
    p.append(R(6, 12, 18, 30, main_sh, rx=3))
    p.append(R(7, 13, 16, 28, main, rx=3))
    p.append(R(8, 14, 6, 22, main_hi))
    # Foot outline
    p.append(R(4, 40, 28, 16, OUTLINE, rx=4))
    p.append(R(6, 42, 24, 12, main, rx=3))
    p.append(R(7, 43, 12, 8, main_hi))
    # Sole
    p.append(R(4, 52, 30, 8, OUTLINE, rx=3))
    p.append(R(6, 54, 26, 5, sole))
    p.append(R(7, 54, 12, 2, sole_hi))
    # Buckle
    if buckle:
        p.append(R(8, 26, 12, 8, OUTLINE, rx=2))
        p.append(R(9, 27, 10, 6, buckle, rx=1))
        p.append(Ci(14, 30, 2, lighten(buckle, 0.4)))
    # Trim line
    p.append(R(4, 40, 22, 3, trim))
    # ── Right boot (mirrored, offset right) ──
    ox = 32
    p.append(R(ox + 2, 10, 22, 34, OUTLINE, rx=4))
    p.append(R(ox + 4, 12, 18, 30, main_sh, rx=3))
    p.append(R(ox + 5, 13, 16, 28, main, rx=3))
    p.append(R(ox + 12, 14, 6, 22, main_hi))
    p.append(R(ox, 40, 28, 16, OUTLINE, rx=4))
    p.append(R(ox + 2, 42, 24, 12, main, rx=3))
    p.append(R(ox + 12, 43, 10, 8, main_hi))
    p.append(R(ox, 52, 30, 8, OUTLINE, rx=3))
    p.append(R(ox + 2, 54, 26, 5, sole))
    p.append(R(ox + 12, 54, 10, 2, sole_hi))
    if buckle:
        p.append(R(ox + 16, 26, 12, 8, OUTLINE, rx=2))
        p.append(R(ox + 17, 27, 10, 6, buckle, rx=1))
        p.append(Ci(ox + 22, 30, 2, lighten(buckle, 0.4)))
    p.append(R(ox + 2, 40, 22, 3, trim))
    return svg_wrap(p)


# ─── SHAPE: RING ──────────────────────────────────────────────────────────────

def make_ring(band, gem=None, gem2=None):
    band_sh = darken(band, 0.3)
    band_hi = lighten(band, 0.4)
    p = []
    # Outer ring (band)
    p.append(Ci(32, 36, 22, OUTLINE))
    p.append(Ci(32, 36, 20, band_sh))
    p.append(Ci(32, 36, 18, band))
    # Inner cutout (hole)
    p.append(Ci(32, 36, 11, OUTLINE))
    p.append(Ci(32, 36, 9, '#1A1428'))
    # Highlight arc (simulated with a lighter circle segment - use polygon)
    p.append(Poly([(22, 22), (32, 16), (42, 22), (40, 20), (32, 14), (24, 20)], band_hi))
    # Gem setting (top of ring)
    if gem:
        p.append(Ci(32, 13, 9, OUTLINE))
        p.append(Ci(32, 13, 7, darken(gem, 0.2)))
        p.append(Ci(32, 13, 6, gem))
        p.append(Ci(30, 11, 2, lighten(gem, 0.5)))
        # Prongs
        for dx in [-5, 5]:
            p.append(R(32 + dx - 1, 16, 2, 4, band_sh))
        if gem2:
            p.append(Ci(32, 13, 3, gem2))
    return svg_wrap(p)


# ─── SHAPE: POTION ────────────────────────────────────────────────────────────

def make_potion(liquid, bottle='#C8E8F8', cork='#C89020'):
    liq_hi = lighten(liquid, 0.4)
    liq_sh = darken(liquid, 0.3)
    p = []
    # Cork outline
    p.append(R(26, 2, 12, 10, OUTLINE, rx=3))
    p.append(R(27, 3, 10, 8, cork, rx=2))
    p.append(R(28, 3, 4, 4, lighten(cork, 0.35)))
    # Neck outline
    p.append(R(24, 10, 16, 10, OUTLINE, rx=2))
    p.append(R(26, 11, 12, 8, darken(bottle, 0.1), rx=2))
    # Body outline
    p.append(R(10, 18, 44, 40, OUTLINE, rx=14))
    # Body glass (outer ring / highlight)
    p.append(R(12, 20, 40, 36, darken(bottle, 0.15), rx=12))
    p.append(R(14, 22, 36, 32, bottle, rx=10))
    # Liquid inside
    p.append(R(16, 30, 32, 22, liq_sh, rx=8))
    p.append(R(18, 32, 28, 18, liquid, rx=6))
    p.append(R(20, 34, 10, 12, liq_hi, rx=4))
    # Bubbles
    p.append(Ci(24, 36, 3, lighten(liquid, 0.5)))
    p.append(Ci(34, 40, 2, lighten(liquid, 0.5)))
    # Glass reflection (left highlight)
    p.append(R(14, 22, 6, 18, lighten(bottle, 0.5), rx=3))
    # Base shadow
    p.append(R(16, 52, 32, 6, darken(bottle, 0.2), rx=8))
    return svg_wrap(p)


# ─── SHAPE: HAT CONIQUE ───────────────────────────────────────────────────────

def make_hat_cone(main, brim=None, star=None):
    if brim is None:
        brim = darken(main, 0.2)
    main_hi = lighten(main, 0.3)
    main_sh = darken(main, 0.25)
    p = []
    # Cone body (triangle)
    p.append(Poly([(10, 50), (54, 50), (32, 4)], OUTLINE))
    p.append(Poly([(12, 50), (52, 50), (32, 6)], main_sh))
    p.append(Poly([(14, 50), (50, 50), (32, 8)], main))
    # Cone highlight (left face)
    p.append(Poly([(14, 50), (32, 50), (32, 8)], main_hi))
    p.append(Poly([(16, 50), (30, 50), (32, 10)], lighten(main, 0.1)))
    # Stars / decoration
    if star:
        for sx, sy, sr in [(24, 22, 3), (40, 32, 2.5), (22, 38, 2)]:
            p.append(Ci(sx, sy, sr, OUTLINE))
            p.append(Ci(sx, sy, sr - 1, star))
    # Tip sparkle
    p.append(Ci(32, 6, 3, lighten(main, 0.6)))
    # Brim outline
    p.append(R(4, 48, 56, 12, OUTLINE, rx=6))
    p.append(R(6, 49, 52, 10, darken(brim, 0.15), rx=5))
    p.append(R(8, 50, 48, 8, brim, rx=4))
    p.append(R(10, 51, 22, 4, lighten(brim, 0.3), rx=3))
    return svg_wrap(p)


# ─── SHAPE: COURONNE ──────────────────────────────────────────────────────────

def make_crown(main, gem1, gem2=None):
    if gem2 is None:
        gem2 = darken(gem1, 0.3)
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.35)
    p = []
    # Base band outline
    p.append(R(6, 36, 52, 22, OUTLINE, rx=3))
    p.append(R(8, 38, 48, 18, main_sh, rx=2))
    p.append(R(10, 39, 44, 16, main, rx=2))
    p.append(R(12, 40, 20, 6, main_hi))
    # Inner decorations on band
    for xi in [14, 26, 38, 50]:
        p.append(R(xi, 42, 4, 8, darken(main, 0.15)))
    # Crown spikes (5 points)
    spike_bases = [8, 18, 28, 38, 48]
    spike_heights = [10, 20, 8, 20, 10]  # center higher
    for bx, height in zip(spike_bases, spike_heights):
        tip_y = 36 - height
        p.append(Poly([(bx, 36), (bx + 8, 36), (bx + 4, tip_y)], OUTLINE))
        p.append(Poly([(bx + 1, 36), (bx + 7, 36), (bx + 4, tip_y + 2)], main_sh))
        p.append(Poly([(bx + 2, 36), (bx + 6, 36), (bx + 4, tip_y + 3)], main))
    # Gems on spikes
    gem_positions = [(12, 24), (22, 14), (32, 26), (42, 14), (52, 24)]
    for i, (gx, gy) in enumerate(gem_positions):
        g = gem1 if i % 2 == 0 else (gem2 or gem1)
        p.append(Ci(gx, gy, 4, OUTLINE))
        p.append(Ci(gx, gy, 3, g))
        p.append(Ci(gx - 1, gy - 1, 1, lighten(g, 0.5)))
    # Central gem (big)
    p.append(Ci(32, 47, 6, OUTLINE))
    p.append(Ci(32, 47, 5, gem1))
    p.append(Ci(31, 45, 2, lighten(gem1, 0.5)))
    return svg_wrap(p)


# ─── SHAPE: BONNET ────────────────────────────────────────────────────────────

def make_beanie(main, pom=None, stripe=None):
    if pom is None:
        pom = lighten(main, 0.5)
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.3)
    p = []
    # Beanie dome
    p.append(R(8, 14, 48, 38, OUTLINE, rx=14))
    p.append(R(10, 16, 44, 34, main_sh, rx=12))
    p.append(R(12, 18, 40, 30, main, rx=10))
    p.append(R(14, 20, 16, 22, main_hi))
    # Ribbed brim
    p.append(R(6, 48, 52, 12, OUTLINE, rx=3))
    p.append(R(8, 49, 48, 10, darken(main, 0.3), rx=2))
    # Rib lines
    for xi in range(10, 56, 8):
        p.append(R(xi, 49, 3, 10, darken(main, 0.45)))
    # Stripe (optional)
    if stripe:
        p.append(R(10, 30, 44, 8, darken(stripe, 0.1), rx=3))
        p.append(R(12, 31, 40, 6, stripe, rx=2))
    # Pompom
    p.append(Ci(32, 12, 11, OUTLINE))
    p.append(Ci(32, 12, 9, darken(pom, 0.1)))
    p.append(Ci(32, 12, 8, pom))
    p.append(Ci(30, 10, 3, lighten(pom, 0.4)))
    return svg_wrap(p)


# ─── SHAPE: BANDANA ───────────────────────────────────────────────────────────

def make_bandana(main, knot=None):
    if knot is None:
        knot = darken(main, 0.2)
    main_sh = darken(main, 0.2)
    main_hi = lighten(main, 0.4)
    p = []
    # Bandana band (wraps around head area)
    p.append(R(4, 20, 44, 20, OUTLINE, rx=4))
    p.append(R(6, 22, 40, 16, main_sh, rx=3))
    p.append(R(8, 23, 36, 14, main, rx=3))
    p.append(R(10, 24, 16, 8, main_hi, rx=2))
    # Fold line
    p.append(R(8, 32, 36, 2, darken(main, 0.15)))
    # Pattern dots
    for xi in [14, 22, 30]:
        p.append(Ci(xi, 30, 2, darken(main, 0.25)))
    # Knot on right side
    p.append(Ci(52, 30, 10, OUTLINE))
    p.append(Ci(52, 30, 8, darken(knot, 0.15)))
    p.append(Ci(52, 30, 7, knot))
    p.append(Ci(50, 28, 2, lighten(knot, 0.4)))
    # Tails
    p.append(Poly([(48, 36), (56, 36), (60, 56), (52, 54)], OUTLINE))
    p.append(Poly([(49, 37), (55, 37), (58, 54), (52, 52)], main_sh))
    p.append(Poly([(50, 38), (54, 38), (56, 52), (52, 51)], main))
    p.append(Poly([(48, 36), (52, 36), (50, 56), (44, 58)], OUTLINE))
    p.append(Poly([(49, 37), (51, 37), (49, 54), (45, 56)], main_sh))
    p.append(Poly([(49, 38), (51, 38), (49, 52), (46, 54)], main))
    return svg_wrap(p)


# ─── SHAPE: OUTFIT / ROBE ─────────────────────────────────────────────────────

def make_outfit(main, trim, gem=None):
    main_sh = darken(main, 0.22)
    main_hi = lighten(main, 0.32)
    trim_hi = lighten(trim, 0.35)
    p = []
    # Collar / neckline
    p.append(R(22, 4, 20, 8, OUTLINE, rx=6))
    p.append(R(24, 5, 16, 6, darken(main, 0.1), rx=5))
    # Shoulders
    p.append(R(4, 10, 18, 14, OUTLINE, rx=4))
    p.append(R(6, 12, 14, 10, main_sh, rx=3))
    p.append(R(7, 13, 10, 8, main, rx=2))
    p.append(R(42, 10, 18, 14, OUTLINE, rx=4))
    p.append(R(44, 12, 14, 10, main_sh, rx=3))
    p.append(R(47, 13, 10, 8, main, rx=2))
    # Body outline
    p.append(R(10, 18, 44, 40, OUTLINE, rx=5))
    # Body
    p.append(R(12, 20, 40, 36, main_sh, rx=4))
    p.append(R(14, 21, 36, 34, main, rx=3))
    p.append(R(16, 22, 14, 28, main_hi))
    # Trim (collar + hem)
    p.append(R(10, 18, 44, 6, trim))
    p.append(R(12, 19, 40, 4, trim_hi))
    p.append(R(10, 50, 44, 8, trim))
    p.append(R(12, 51, 40, 4, trim_hi))
    # Center button line
    p.append(R(31, 26, 2, 24, darken(main, 0.15)))
    for yy in [28, 34, 40]:
        p.append(Ci(32, yy, 2, trim))
        p.append(Ci(32, yy, 1, trim_hi))
    # Gem / brooch
    if gem:
        p.append(Ci(32, 23, 5, OUTLINE))
        p.append(Ci(32, 23, 4, gem))
        p.append(Ci(31, 22, 1.5, lighten(gem, 0.5)))
    return svg_wrap(p)


# ─── SHAPE: PANTS ─────────────────────────────────────────────────────────────

def make_pants(main, trim=None):
    if trim is None:
        trim = darken(main, 0.2)
    main_sh = darken(main, 0.22)
    main_hi = lighten(main, 0.3)
    p = []
    # Waistband
    p.append(R(8, 4, 48, 12, OUTLINE, rx=4))
    p.append(R(10, 5, 44, 10, darken(trim, 0.1), rx=3))
    p.append(R(12, 6, 40, 6, trim, rx=2))
    # Belt buckle
    p.append(R(28, 5, 8, 8, OUTLINE, rx=2))
    p.append(R(29, 6, 6, 6, lighten(trim, 0.4), rx=1))
    # Crotch area
    p.append(R(8, 14, 48, 10, OUTLINE))
    p.append(R(10, 15, 44, 8, main_sh))
    p.append(R(12, 16, 40, 6, main))
    # Left leg
    p.append(R(6, 22, 24, 38, OUTLINE, rx=4))
    p.append(R(8, 24, 20, 34, main_sh, rx=3))
    p.append(R(10, 25, 16, 32, main, rx=2))
    p.append(R(11, 26, 6, 28, main_hi))
    # Right leg
    p.append(R(34, 22, 24, 38, OUTLINE, rx=4))
    p.append(R(36, 24, 20, 34, main_sh, rx=3))
    p.append(R(38, 25, 16, 32, main, rx=2))
    p.append(R(47, 26, 6, 28, main_hi))
    # Leg crease / fold detail
    p.append(R(10, 46, 16, 2, darken(main, 0.12)))
    p.append(R(38, 46, 16, 2, darken(main, 0.12)))
    # Bottom trim
    p.append(R(8, 56, 22, 6, trim))
    p.append(R(34, 56, 22, 6, trim))
    return svg_wrap(p)


# ─── SHAPE: SHOES ─────────────────────────────────────────────────────────────

def make_shoes(main, sole='#3D2B1A', trim=None, buckle=None):
    if trim is None:
        trim = darken(main, 0.2)
    main_sh = darken(main, 0.22)
    main_hi = lighten(main, 0.35)
    sole_hi = lighten(sole, 0.3)
    p = []
    # ── Left shoe ──
    # Upper (vamp) outline
    p.append(R(4, 20, 26, 26, OUTLINE, rx=6))
    p.append(R(6, 22, 22, 22, main_sh, rx=5))
    p.append(R(7, 23, 20, 20, main, rx=4))
    p.append(R(8, 24, 9, 14, main_hi))
    # Tongue / lacing area
    p.append(R(12, 16, 12, 10, OUTLINE, rx=3))
    p.append(R(13, 17, 10, 8, lighten(main, 0.1), rx=2))
    # Toe cap
    p.append(R(4, 36, 14, 10, OUTLINE, rx=5))
    p.append(R(5, 37, 12, 8, darken(main, 0.15), rx=4))
    # Sole
    p.append(R(2, 44, 32, 10, OUTLINE, rx=4))
    p.append(R(4, 46, 28, 7, sole, rx=3))
    p.append(R(5, 46, 12, 3, sole_hi))
    # Buckle / strap
    if buckle:
        p.append(R(10, 26, 12, 6, OUTLINE, rx=2))
        p.append(R(11, 27, 10, 4, buckle, rx=1))
        p.append(Ci(16, 29, 2, lighten(buckle, 0.4)))
    # Trim line
    p.append(R(4, 36, 26, 2, trim))
    # ── Right shoe (mirrored) ──
    ox = 34
    p.append(R(ox + 2, 20, 26, 26, OUTLINE, rx=6))
    p.append(R(ox + 4, 22, 22, 22, main_sh, rx=5))
    p.append(R(ox + 5, 23, 20, 20, main, rx=4))
    p.append(R(ox + 13, 24, 9, 14, main_hi))
    p.append(R(ox + 6, 16, 12, 10, OUTLINE, rx=3))
    p.append(R(ox + 7, 17, 10, 8, lighten(main, 0.1), rx=2))
    p.append(R(ox + 14, 36, 14, 10, OUTLINE, rx=5))
    p.append(R(ox + 15, 37, 12, 8, darken(main, 0.15), rx=4))
    p.append(R(ox, 44, 32, 10, OUTLINE, rx=4))
    p.append(R(ox + 2, 46, 28, 7, sole, rx=3))
    p.append(R(ox + 16, 46, 12, 3, sole_hi))
    if buckle:
        p.append(R(ox + 10, 26, 12, 6, OUTLINE, rx=2))
        p.append(R(ox + 11, 27, 10, 4, buckle, rx=1))
        p.append(Ci(ox + 16, 29, 2, lighten(buckle, 0.4)))
    p.append(R(ox + 2, 36, 26, 2, trim))
    return svg_wrap(p)


# ─── SHAPE: AURA ──────────────────────────────────────────────────────────────

def make_aura(main, core=None):
    if core is None:
        core = lighten(main, 0.5)
    main_tr = main  # we'll use opacity via the color
    p = []
    # Outer glow rings
    cx, cy = 32, 32
    for r_val, alpha in [(30, '18'), (24, '28'), (18, '38')]:
        hi = lighten(main, 0.2) if r_val == 18 else main
        p.append(Ci(cx, cy, r_val, hi + alpha))
    # 8 radiating spikes
    spike_defs = [
        (32, 2, 32, 12),    # top
        (32, 52, 32, 62),   # bottom
        (2, 32, 12, 32),    # left
        (52, 32, 62, 32),   # right (will clip)
        (10, 10, 18, 18),   # top-left
        (54, 10, 46, 18),   # top-right
        (10, 54, 18, 46),   # bot-left
        (54, 54, 46, 46),   # bot-right
    ]
    # Draw spikes as small elongated diamond shapes
    for i, (x1, y1, x2, y2) in enumerate(spike_defs):
        mx, my = (x1 + x2) // 2, (y1 + y2) // 2
        dx, dy = x2 - x1, y2 - y1
        length = (dx**2 + dy**2) ** 0.5
        if length == 0:
            continue
        # perpendicular offset for diamond width (3px wide)
        px_off = 3 * (-dy / length)
        py_off = 3 * (dx / length)
        pts = [
            (x1, y1),
            (mx + px_off, my + py_off),
            (x2, y2),
            (mx - px_off, my - py_off),
        ]
        p.append(Poly(pts, main + 'BB'))
        p.append(Poly(pts, core + '88'))
    # Center star / core
    for r_val, col in [(12, OUTLINE), (10, darken(main, 0.1)), (8, main), (5, core)]:
        p.append(Ci(cx, cy, r_val, col))
    p.append(Ci(cx - 2, cy - 2, 3, lighten(core, 0.5)))
    # 4-pointed star overlay
    star_pts = [(32, 16), (34, 30), (48, 32), (34, 34), (32, 48), (30, 34), (16, 32), (30, 30)]
    p.append(Poly(star_pts, main + 'CC'))
    return svg_wrap(p)


# ─── SHAPE: CRYSTAL ───────────────────────────────────────────────────────────

def make_crystal(main, edge=None):
    if edge is None:
        edge = darken(main, 0.3)
    main_hi = lighten(main, 0.45)
    main_sh = darken(main, 0.2)
    p = []
    # Main crystal body (hexagonal/gem shape)
    p.append(Poly([(32, 2), (52, 16), (56, 40), (40, 58), (24, 58), (8, 40), (12, 16)], OUTLINE))
    p.append(Poly([(32, 4), (50, 17), (54, 40), (39, 56), (25, 56), (10, 40), (14, 17)], main_sh))
    p.append(Poly([(32, 6), (48, 18), (52, 40), (38, 54), (26, 54), (12, 40), (16, 18)], main))
    # Facets (inner lines)
    p.append(Poly([(32, 6), (52, 40), (32, 54), (12, 40)], main + '60'))
    p.append(Poly([(32, 6), (48, 18), (32, 22), (16, 18)], main_hi + '90'))
    # Highlight facet (top-left face)
    p.append(Poly([(16, 18), (32, 6), (32, 22)], main_hi))
    p.append(Poly([(16, 18), (20, 24), (28, 20), (32, 6)], lighten(main_hi, 0.3)))
    # Shine sparkle
    p.append(Ci(22, 20, 4, lighten(main, 0.6)))
    p.append(Ci(22, 20, 2, '#FFFFFF'))
    # Edge glow
    p.append(Poly([(32, 2), (52, 16), (50, 17), (32, 4), (14, 17), (12, 16)], edge + '60'))
    return svg_wrap(p)


# ─── SHAPE: STONE ─────────────────────────────────────────────────────────────

def make_stone(main='#8090A0', cracks=True):
    main_sh = darken(main, 0.25)
    main_hi = lighten(main, 0.3)
    p = []
    # Stone irregular shape
    p.append(Poly([(16, 6), (48, 4), (58, 20), (56, 46), (40, 60), (20, 58), (6, 44), (8, 18)], OUTLINE))
    p.append(Poly([(17, 8), (47, 6), (56, 21), (54, 45), (39, 58), (21, 56), (8, 43), (10, 19)], main_sh))
    p.append(Poly([(18, 10), (46, 8), (54, 22), (52, 44), (38, 56), (22, 54), (10, 42), (12, 20)], main))
    # Highlight
    p.append(Poly([(22, 12), (40, 10), (48, 22), (28, 18)], main_hi))
    p.append(Poly([(24, 14), (36, 12), (42, 20), (28, 18)], lighten(main_hi, 0.3)))
    # Cracks
    if cracks:
        p.append(Path('M 30 22 L 26 34 L 32 42', 'none', 2, OUTLINE))
        p.append(Path('M 40 28 L 44 38', 'none', 2, OUTLINE))
        p.append(Path('M 22 36 L 28 44', 'none', 1.5, darken(main, 0.15)))
    # Shadow at bottom
    p.append(Poly([(10, 42), (54, 44), (52, 54), (38, 58), (22, 56), (8, 46)], darken(main, 0.12) + '80'))
    return svg_wrap(p)


# ─── SHAPE: ESSENCE MYTHIQUE ──────────────────────────────────────────────────

def make_essence(main='#FC8181', inner='#F6E05E'):
    main_hi = lighten(main, 0.4)
    inner_hi = lighten(inner, 0.4)
    p = []
    # Outer swirl rings
    p.append(Ci(32, 32, 28, main + '20'))
    p.append(Ci(32, 32, 22, main + '35'))
    p.append(Ci(32, 32, 16, main + '55'))
    # Outer ring outline
    p.append(Ci(32, 32, 28, OUTLINE + '40'))
    # 6 outer particles
    import math
    for i in range(6):
        angle = math.radians(i * 60)
        px = 32 + 22 * math.cos(angle)
        py = 32 + 22 * math.sin(angle)
        p.append(Ci(px, py, 5, OUTLINE))
        p.append(Ci(px, py, 4, main))
        p.append(Ci(px, py, 2, main_hi))
    # 8-pointed star center
    star8 = []
    for i in range(8):
        angle = math.radians(i * 45)
        r_val = 12 if i % 2 == 0 else 7
        star8.append((32 + r_val * math.cos(angle), 32 + r_val * math.sin(angle)))
    p.append(Poly(star8, OUTLINE))
    star8_inner = []
    for i in range(8):
        angle = math.radians(i * 45)
        r_val = 10 if i % 2 == 0 else 5
        star8_inner.append((32 + r_val * math.cos(angle), 32 + r_val * math.sin(angle)))
    p.append(Poly(star8_inner, main))
    # Core
    p.append(Ci(32, 32, 7, OUTLINE))
    p.append(Ci(32, 32, 6, inner))
    p.append(Ci(32, 32, 3, inner_hi))
    p.append(Ci(30, 30, 1.5, '#FFFFFF'))
    # Trailing sparkles
    for sx, sy in [(12, 14), (52, 12), (14, 50), (50, 52)]:
        p.append(Ci(sx, sy, 2, main + 'AA'))
        p.append(Ci(sx, sy, 1, main_hi))
    return svg_wrap(p)


# ─────────────────────────────────────────────────────────────────────────────
# GENERATE ALL ITEMS
# ─────────────────────────────────────────────────────────────────────────────

print('🎨 Génération des assets SVG Sameva...\n')
print('📦 Armes:')

# Weapons
save('sword_rusty.svg', make_sword(
    blade='#B08060', blade_hi='#D4A880',
    guard='#B07820', guard_hi='#D4A030',
    handle='#6B3020'))

save('sword_hunter.svg', make_sword(
    blade='#C8C8D8', blade_hi='#E8E8F0',
    guard='#4299E1', guard_hi='#90CDF4',
    handle='#2D3748', tip_gem='#4FD1C5'))

save('sword_legendary.svg', make_sword(
    blade='#F6C027', blade_hi='#FFEAA0',
    guard='#F6C027', guard_hi='#FFFFFF',
    handle='#805AD5', pommel='#553C9A', tip_gem='#FC8181'))

print('🛡️  Armures:')

# Armors
save('armor_tunic.svg', make_armor(
    main='#C8B090', trim='#8B6040', gem=None))

save('armor_mail.svg', make_armor(
    main='#909098', trim='#C8962A', gem='#4299E1'))

save('armor_epic.svg', make_armor(
    main='#805AD5', trim='#F6C027', gem='#FC8181'))

print('⛑️  Casques:')

# Helmets
save('helmet_hat.svg', make_helmet(
    main='#8B5E3C', visor='#C8A870', trim='#C8962A'))

save('helmet_sage.svg', make_helmet(
    main='#4A5568', visor='#2D3748', trim='#805AD5', gem='#F6C027'))

print('👢 Bottes:')

# Boots
save('boots_worn.svg', make_boots(
    main='#6B3820', sole='#3D2210'))

save('boots_merc.svg', make_boots(
    main='#4A2810', sole='#2A1808', buckle='#C8962A'))

print('💍 Anneaux:')

# Rings
save('ring_bronze.svg', make_ring(
    band='#CD7F32', gem='#C89020', gem2='#F6C027'))

save('ring_mystic.svg', make_ring(
    band='#805AD5', gem='#F6C027', gem2='#FFFFFF'))

print('🧪 Potions:')

# Potions
save('potion_heal.svg', make_potion(
    liquid='#E53E3E', bottle='#FFE4E1'))

save('potion_xp.svg', make_potion(
    liquid='#F6C027', bottle='#FFFDE7'))

save('potion_gold.svg', make_potion(
    liquid='#ED8936', bottle='#FFF8E1', cork='#8B4513'))

print('\n🎩 Cosmétiques — Chapeaux:')

# Cosmetic Hats
save('hat_cone_violet.svg', make_hat_cone(main='#805AD5', star='#F6C027'))
save('hat_cone_blue.svg', make_hat_cone(main='#4299E1', star='#76E4F7'))
save('hat_crown_gold.svg', make_crown(main='#F6C027', gem1='#E53E3E', gem2='#FC8181'))
save('hat_crown_cyan.svg', make_crown(main='#76E4F7', gem1='#805AD5', gem2='#F6C027'))
save('hat_beanie_red.svg', make_beanie(main='#E53E3E', pom='#FFFFFF'))
save('hat_beanie_violet.svg', make_beanie(main='#553C9A', pom='#B794F4', stripe='#F6C027'))
save('hat_bandana_teal.svg', make_bandana(main='#4FD1C5'))
save('hat_bandana_orange.svg', make_bandana(main='#ED8936'))

print('👗 Cosmétiques — Tenues:')

# Cosmetic Outfits
save('outfit_teal.svg', make_outfit(main='#4FD1C5', trim='#2C7A7B'))
save('outfit_violet.svg', make_outfit(main='#805AD5', trim='#553C9A', gem='#F6C027'))
save('outfit_navy.svg', make_outfit(main='#2C5282', trim='#C8962A'))
save('outfit_gold.svg', make_outfit(main='#D69E2E', trim='#744210', gem='#FC8181'))
save('outfit_red.svg', make_outfit(main='#C53030', trim='#1A1428'))

print('👖 Cosmétiques — Pantalons:')

# Cosmetic Pants
save('pants_dark.svg', make_pants(main='#2D3748', trim='#4A5568'))
save('pants_purple.svg', make_pants(main='#553C9A', trim='#B794F4'))
save('pants_red.svg', make_pants(main='#C53030', trim='#FC8181'))
save('pants_navy.svg', make_pants(main='#1A365D', trim='#2C5282'))
save('pants_gold.svg', make_pants(main='#D69E2E', trim='#744210'))

print('👟 Cosmétiques — Chaussures:')

# Cosmetic Shoes
save('shoes_brown.svg', make_shoes(main='#5C3D1E', sole='#2A1808'))
save('shoes_gold.svg', make_shoes(main='#B7791F', sole='#744210', buckle='#F6C027'))
save('shoes_tan.svg', make_shoes(main='#C68642', sole='#8B4513'))
save('shoes_cyan.svg', make_shoes(main='#4FD1C5', sole='#2C7A7B', buckle='#76E4F7'))
save('shoes_mythic.svg', make_shoes(main='#FC8181', sole='#C53030', buckle='#F6C027'))

print('✨ Cosmétiques — Auras:')

# Cosmetic Auras
save('aura_gold.svg', make_aura(main='#F6C027', core='#FFFFFF'))
save('aura_teal.svg', make_aura(main='#4FD1C5', core='#E6FFFA'))
save('aura_fire.svg', make_aura(main='#ED8936', core='#F6C027'))
save('aura_shadow.svg', make_aura(main='#44337A', core='#B794F4'))
save('aura_holy.svg', make_aura(main='#E2E8F0', core='#FFFFFF'))

print('\n📦 Matériaux:')

# Materials
save('material_stone.svg', make_stone(main='#8090A0'))
save('material_crystal.svg', make_crystal(main='#76E4F7', edge='#4FD1C5'))
save('material_essence.svg', make_essence(main='#FC8181', inner='#F6C027'))

print(f'\n✅ {len(os.listdir(OUTPUT_DIR))} assets générés dans assets/items/')
