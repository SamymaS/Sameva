// Bibliothèque de pilotage robuste de l'app (banc d'essai Sameva).
import { ouvrir, capture, pause } from "./pilote.mjs";
export { ouvrir, capture, pause };

/** Libellés accessibles visibles (arbre sémantique Flutter). */
export const libelles = (page) => page.$$eval("flt-semantics", (els) =>
  [...new Set(els.map((e) => (e.getAttribute("aria-label") || "").trim()
    || (e.childElementCount === 0 ? e.textContent.trim() : "")).filter(Boolean))]);

/** Le texte est-il visible maintenant ? */
export async function voit(page, texte) {
  return (await page.getByText(texte, { exact: false }).count()) > 0;
}

/** Attend un texte (sondage de l'arbre sémantique). */
export async function attendre(page, texte, timeout = 20000) {
  const fin = Date.now() + timeout;
  while (Date.now() < fin) {
    if (await voit(page, texte)) return true;
    await pause(400);
  }
  throw new Error(`Texte introuvable après ${timeout} ms : « ${texte} »`);
}

/** Touche un élément par son texte, en attendant qu'il apparaisse. */
export async function toucher(page, texte, { timeout = 20000, exact = false } = {}) {
  const fin = Date.now() + timeout;
  let derniere;
  while (Date.now() < fin) {
    const loc = page.getByText(texte, { exact }).first();
    if (await loc.count()) {
      try { await loc.click({ timeout: 3000 }); return; } catch (e) { derniere = e; }
    }
    await pause(400);
  }
  throw new Error(`Impossible de toucher « ${texte} » : ${derniere?.message?.split("\n")[0] ?? "absent"}`);
}

/** Touche un bouton par son nom accessible (icônes, FAB...). */
export async function toucherRole(page, role, nom, timeout = 15000) {
  await page.getByRole(role, { name: nom }).first().click({ timeout });
}

/** Saisit du texte dans le champ de saisie dont le libellé contient `champ`. */
export async function saisir(page, champ, valeur) {
  const loc = page.getByRole("textbox", { name: champ }).first();
  await loc.click({ timeout: 15000 });
  await page.keyboard.press("Control+A");
  await page.keyboard.type(valeur, { delay: 15 });
}

/** Ferme les dialogues connus (récompense du jour, résumé hebdo...) jusqu'à stabilité. */
export async function fermerModales(page, { boutons = ["Récupérer", "Nouvelle semaine", "Plus tard", "Compris"], calme = 3000, max = 30000 } = {}) {
  const fin = Date.now() + max;
  let dernierClic = Date.now();
  const fermes = [];
  while (Date.now() < fin && Date.now() - dernierClic < calme) {
    let clique = false;
    for (const b of boutons) {
      const loc = page.getByText(b, { exact: false }).first();
      if (await loc.count()) {
        try { await loc.click({ timeout: 2000 }); fermes.push(b); clique = true; dernierClic = Date.now(); await pause(800); } catch { /* animation */ }
      }
    }
    if (!clique) await pause(400);
  }
  return fermes;
}

/** Parcours d'entrée : invité + onboarding, jusqu'au Sanctuaire sans dialogue. */
export async function entrerCommeInvite(page) {
  await toucher(page, "Continuer en tant", { timeout: 60000 });
  for (let i = 0; i < 3; i++) await toucher(page, "Suivant");
  await toucher(page, "Commencer l");
  await attendre(page, "Sanctuaire", 30000);
  return fermerModales(page);
}

/** Suite de vérifications avec compte rendu. */
export function rapport() {
  const lignes = [];
  let ok = 0, ko = 0;
  return {
    verifier(nom, cond, info) {
      if (cond) { ok++; lignes.push(`  ok    ${nom}`); } else { ko++; lignes.push(`  ÉCHEC ${nom}${info ? " : " + JSON.stringify(info).slice(0, 300) : ""}`); }
    },
    async etape(nom, fn) {
      try { await fn(); } catch (e) { ko++; lignes.push(`  ÉCHEC ${nom} : ${e.message.split("\n")[0]}`); return false; }
      return true;
    },
    fin() { lignes.push(`\n${ok} réussis, ${ko} en échec`); console.log(lignes.join("\n")); return ko; },
  };
}
