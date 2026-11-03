// Exploration : node explore.mjs '<étapes JSON>'  (après onboarding invité)
// étape : {"toucher":"texte"} | {"role":["button","nom"]} | {"saisir":["champ","valeur"]} | {"defiler":600} | {"capture":"nom"}
import { ouvrir, capture, pause, libelles, toucher, toucherRole, saisir, entrerCommeInvite, fermerModales } from "./banc.mjs";
const { browser, page, journal } = await ouvrir();
console.log("Modales fermées :", await entrerCommeInvite(page));
for (const e of JSON.parse(process.argv[2] ?? "[]")) {
  try {
    if (e.toucher) await toucher(page, e.toucher);
    if (e.role) await toucherRole(page, e.role[0], e.role[1]);
    if (e.saisir) await saisir(page, e.saisir[0], e.saisir[1]);
    if (e.taper) await page.keyboard.type(e.taper, { delay: 20 });
    if (e.defiler) await page.mouse.wheel(0, e.defiler);
    if (e.photo) {
      // Caméra simulée : la version web d'image_picker ouvre un sélecteur de fichier.
      const [chooser] = await Promise.all([
        page.waitForEvent("filechooser", { timeout: 15000 }),
        e.photo.xy ? page.mouse.click(e.photo.xy[0], e.photo.xy[1]) : toucher(page, e.photo.toucher),
      ]);
      await chooser.setFiles(e.photo.fichier);
    }
    if (e.xy) await page.mouse.click(e.xy[0], e.xy[1]);
    if (e.modales) await fermerModales(page);
    await pause(e.attente ?? 1500);
    if (e.capture) console.log(await capture(page, e.capture));
  } catch (err) { console.log("Étape impossible :", JSON.stringify(e), err.message.split("\n")[0]); await capture(page, "erreur"); break; }
}
console.log("Libellés :", JSON.stringify(await libelles(page)).slice(0, 2500));
console.log("Erreurs console :", journal.filter((l) => /error|exception/i.test(l)).slice(-8).join("\n"));
await browser.close();
