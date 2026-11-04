// Exploration pas à pas : node etape.mjs <scénario>
// Chaque étape capture l'écran et liste les libellés accessibles.
import { ouvrir, capture, pause } from "./pilote.mjs";
const libelles = (page) => page.$$eval("flt-semantics", (els) =>
  [...new Set(els.map((e) => (e.getAttribute("aria-label") || "").trim() || (e.childElementCount === 0 ? e.textContent.trim() : "")).filter(Boolean))]);
const { browser, page, journal } = await ouvrir();
await pause(5000);
const etapes = JSON.parse(process.argv[2] ?? "[]");
let n = 1;
for (const e of etapes) {
  try {
    if (e.texte) await page.getByText(e.texte, { exact: !!e.exact }).first().click({ timeout: 15000 });
    if (e.role) await page.getByRole(e.role, { name: e.nom }).first().click({ timeout: 15000 });
    if (e.saisir) { await page.getByRole("textbox", { name: e.champ }).first().click(); await page.keyboard.type(e.saisir); }
    if (e.touche) await page.keyboard.press(e.touche);
    if (e.xy) await page.mouse.click(e.xy[0], e.xy[1]);
    if (e.defiler) await page.mouse.wheel(0, e.defiler);
  } catch (err) { console.log(`étape ${n} impossible :`, JSON.stringify(e), err.message.split("\n")[0]); }
  await pause(e.attente ?? 2500);
  if (e.capture !== false) console.log(await capture(page, `${String(n).padStart(2, "0")}_${e.nom_capture ?? "etape"}`));
  n++;
}
console.log("Libellés :", JSON.stringify(await libelles(page)).slice(0, 1500));
console.log("Erreurs :", journal.filter((l) => /error|exception|Erreur/i.test(l)).slice(-10).join("\n"));
await browser.close();
