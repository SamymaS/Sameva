"""Effets sonores chiptune de Sameva, synthétisés (ondes carrées, triangle,
bruit), façon console 8 bits. Aucun échantillon externe : droits entiers."""
import numpy as np, wave, os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT, exist_ok=True)
SR = 22050


def note(n):
    """Fréquence d'une note MIDI."""
    return 440.0 * 2 ** ((n - 69) / 12)


def onde(f, d, forme="carre", rapport=0.5, glisse=None):
    t = np.arange(int(SR * d)) / SR
    freq = np.full_like(t, f) if glisse is None else np.linspace(f, glisse, t.size)
    phase = np.cumsum(freq) / SR % 1.0
    if forme == "carre":
        return np.where(phase < rapport, 1.0, -1.0)
    if forme == "triangle":
        return 4 * np.abs(phase - 0.5) - 1
    if forme == "bruit":
        rng = np.random.default_rng(7)
        pas = max(1, int(SR / max(f, 1)))
        brut = rng.choice([-1.0, 1.0], size=t.size // pas + 1)
        return np.repeat(brut, pas)[: t.size]
    raise ValueError(forme)


def env(x, a=0.005, r=0.08, maintien=1.0):
    n = x.size
    e = np.ones(n) * maintien
    na, nr = int(SR * a), int(SR * r)
    if na: e[:na] = np.linspace(0, maintien, na)
    if nr: e[-nr:] = np.linspace(maintien, 0, nr) if n > nr else e[-nr:]
    return x * e


def seq(notes, d, forme="carre", rapport=0.5, vol=0.3, r=0.04):
    return np.concatenate([env(onde(note(n), d, forme, rapport), r=r) * vol if n else np.zeros(int(SR * d)) for n in notes])


def mix(*pistes):
    n = max(p.size for p in pistes)
    out = np.zeros(n)
    for p in pistes:
        out[: p.size] += p
    return out


def ecrire(nom, x):
    x = np.clip(x / max(1.0, np.abs(x).max() / 0.9), -1, 1)
    data = (x * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(OUT, nom + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)


# Toucher d'interface : clic sec
ecrire("ui_toucher", env(onde(note(84), 0.035, rapport=0.25), r=0.02) * 0.25)

# Pièce d'or : si puis mi aigu (classique)
ecrire("piece", np.concatenate([env(onde(note(83), 0.06), r=0.01) * 0.3, env(onde(note(88), 0.28), r=0.25) * 0.3]))

# Quête accomplie : arpège majeur montant + basse triangle
mel = seq([72, 76, 79, 84, 0, 84], 0.09, rapport=0.25, vol=0.28)
basse = seq([48, 48, 55, 55, 60, 60], 0.09, forme="triangle", vol=0.35)
ecrire("quete_accomplie", mix(mel, basse))

# Montée de niveau : gamme rapide puis accord tenu avec vibrato léger
gamme = seq([60, 62, 64, 65, 67, 69, 71, 72], 0.05, rapport=0.5, vol=0.25, r=0.01)
t = np.arange(int(SR * 0.7)) / SR
accord = sum(np.sign(np.sin(2 * np.pi * note(n) * t + 0.15 * np.sin(2 * np.pi * 6 * t))) for n in (72, 76, 79)) / 3
ecrire("niveau_superieur", np.concatenate([gamme, env(accord, r=0.5) * 0.3]))

# L'Oracle observe : bips de balayage montants/descendants (boucle d'attente)
bips = np.concatenate([env(onde(note(n), 0.07, rapport=0.125), r=0.03) * 0.18 for n in (79, 83, 86, 83)] * 2)
ecrire("oracle_observe", bips)

# Verdict accepté : quinte joyeuse avec éclat
ok = mix(seq([76, 83], 0.1, rapport=0.25, vol=0.3), np.concatenate([np.zeros(int(SR * 0.2)), env(onde(note(88), 0.35, "triangle"), r=0.3) * 0.35]))
ecrire("oracle_accepte", ok)

# Verdict refusé : deux notes descendantes, onde « grinçante »
ko = np.concatenate([env(onde(note(62), 0.12, rapport=0.125), r=0.02) * 0.3,
                     env(onde(note(55), 0.3, rapport=0.125, glisse=note(53)), r=0.2) * 0.3])
ecrire("oracle_refuse", ko)

# Invocation (gacha) : montée en glissando + bruit, puis éclat selon la rareté
montee = env(onde(note(48), 0.7, rapport=0.5, glisse=note(84)), a=0.05, r=0.05) * 0.18
souffle = env(onde(3000, 0.7, "bruit"), a=0.5, r=0.1) * 0.08
for rarete, accord_notes in (("commune", (72,)), ("rare", (72, 79)), ("legendaire", (72, 76, 79, 84))):
    eclat = sum(env(onde(note(n), 0.6, rapport=0.25), r=0.5) for n in accord_notes) / len(accord_notes) * 0.32
    ecrire(f"invocation_{rarete}", np.concatenate([mix(montee, souffle), eclat]))

# Dégâts (PV perdus) : bruit bref descendant
ecrire("degats", env(onde(800, 0.25, "bruit"), r=0.2) * 0.3 + env(onde(note(45), 0.25, glisse=note(33)), r=0.2) * 0.2)

print("ok", sorted(f for f in os.listdir(OUT) if f.endswith(".wav")))
