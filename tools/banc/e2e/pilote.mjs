// Outils de pilotage de l'app Flutter web (banc d'essai).
import { chromium } from "playwright-core";
import fs from "node:fs";

export const APP_URL = process.env.APP_URL ?? "http://127.0.0.1:8080/";
export const SHOTS = process.env.SHOTS ?? "/tmp/sameva-banc/captures";
fs.mkdirSync(SHOTS, { recursive: true });

export async function ouvrir({ largeur = 412, hauteur = 915 } = {}) {
  const browser = await chromium.launch({
    executablePath: "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
    args: ["--no-sandbox", "--use-gl=swiftshader", "--enable-unsafe-swiftshader"],
  });
  // Format d'un téléphone (Galaxy S23 Ultra en CSS : 412 × 915).
  const context = await browser.newContext({
    viewport: { width: largeur, height: hauteur },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: "fr-FR",
    timezoneId: "Europe/Paris",
  });
  const page = await context.newPage();
  const journal = [];
  page.on("console", (m) => journal.push(`[${m.type()}] ${m.text()}`));
  page.on("pageerror", (e) => journal.push(`[pageerror] ${e.message}`));
  await page.goto(APP_URL);
  // Active l'arbre d'accessibilité de Flutter pour trouver les éléments par texte.
  await page.waitForSelector("flt-semantics-placeholder, flutter-view", { timeout: 60000 });
  await page.evaluate(() => document.querySelector("flt-semantics-placeholder")?.click());
  return { browser, page, journal };
}

export async function capture(page, nom) {
  const chemin = `${SHOTS}/${nom}.png`;
  await page.screenshot({ path: chemin });
  return chemin;
}

/** Attend qu'un texte visible apparaisse (via l'arbre d'accessibilité). */
export async function attendreTexte(page, texte, timeout = 20000) {
  await page.getByText(texte, { exact: false }).first().waitFor({ timeout });
}

export async function cliquerTexte(page, texte) {
  await page.getByText(texte, { exact: false }).first().click();
}

export async function pause(ms) {
  await new Promise((r) => setTimeout(r, ms));
}
