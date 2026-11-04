// Ouvre l'app, capture l'écran d'accueil et liste les libellés accessibles.
import { ouvrir, capture, pause } from "./pilote.mjs";
const { browser, page, journal } = await ouvrir();
await pause(6000);
console.log(await capture(page, "00_ouverture"));
const libelles = await page.$$eval("flt-semantics [aria-label], flt-semantics", (els) =>
  [...new Set(els.map((e) => (e.getAttribute("aria-label") || e.textContent || "").trim()).filter(Boolean))].slice(0, 60));
console.log("Libellés :", libelles);
console.log("Console :", journal.slice(-15).join("\n"));
await browser.close();
