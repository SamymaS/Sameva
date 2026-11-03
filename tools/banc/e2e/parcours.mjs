// Suite de bout en bout : l'app web réelle, pilotée comme un joueur, contre le
// banc local (GoTrue + PostgREST + Edge Functions, Oracle simulé).
//
// Usage : node parcours.mjs [filtre]     (ex. node parcours.mjs oracle)
// Prérequis : tools/banc/start.sh puis tools/banc/app.sh
//
// Chaque parcours repart d'un nouvel invité. Les captures sont écrites dans
// $SHOTS (par défaut /tmp/sameva-banc/captures) et listées en cas d'échec.
import { ouvrir, capture, pause, voit, attendre, toucher, entrerCommeInvite, rapport } from "./banc.mjs";

const PHOTOS = process.env.PHOTOS ?? "/tmp/sameva-banc/photos";
const filtre = process.argv[2] ?? "";
const r = rapport();

// Les éléments sont trouvés par leur libellé accessible (comme le ferait un
// lecteur d'écran), jamais par leur position.

async function creerQuete(page, { titre, difficulte = 2, photo = false, capturer = null }) {
  await toucher(page, "Quêtes");
  await attendre(page, "Terminées");
  await pause(800);
  await page.getByRole("button", { name: "Nouvelle quête" }).first().click({ timeout: 15000 });
  await toucher(page, "Quête personnalisée");
  await attendre(page, "Créer la quête");
  await pause(800);
  await page.getByRole("textbox", { name: "Titre de la quête" }).first().click({ timeout: 15000 });
  await page.keyboard.type(titre, { delay: 15 });
  await page.getByRole("button", { name: `Difficulté ${difficulte}` }).first().click({ timeout: 15000 });
  if (photo) await toucher(page, "Photo", { exact: true });
  if (capturer) { await pause(600); await capture(page, capturer); }
  // Ferme le clavier virtuel puis descend jusqu'au bouton.
  await page.keyboard.press("Escape").catch(() => {});
  await page.mouse.wheel(0, 1500);
  await pause(1500);
  await toucher(page, "Créer la quête");
  await attendre(page, titre);
}

/** Appel de l'API du banc avec la session de l'app (comme le ferait l'app). */
async function api(page, chemin, { method = "GET", body } = {}) {
  return page.evaluate(async ({ chemin, method, body }) => {
    const cle = Object.keys(localStorage).find((k) => k.includes("auth-token"));
    const token = JSON.parse(localStorage.getItem(cle) ?? "{}").access_token;
    const r = await fetch(`http://127.0.0.1:54321/rest/v1/${chemin}`, {
      method,
      headers: { apikey: token, Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: r.status, data: await r.json().catch(() => null) };
  }, { chemin, method, body });
}

/** Récompense réellement accordée par le serveur pour une quête. */
async function recompense(page, titre) {
  const { data } = await api(page, `quests?select=reward&title=eq.${encodeURIComponent(titre)}`);
  return data?.[0]?.reward;
}

async function prendrePhoto(page, bouton, fichier) {
  const [chooser] = await Promise.all([
    page.waitForEvent("filechooser", { timeout: 15000 }),
    toucher(page, bouton),
  ]);
  await chooser.setFiles(`${PHOTOS}/${fichier}`);
  await pause(1500);
}

async function parcours(nom, fn) {
  if (filtre && !nom.includes(filtre)) return;
  console.log(`▶ ${nom}`);
  const { browser, page, journal } = await ouvrir();
  try {
    await r.etape(nom, () => fn(page));
  } finally {
    const erreurs = journal.filter((l) => /pageerror|Uncaught|Exception/i.test(l));
    r.verifier(`${nom} : aucune erreur JavaScript`, erreurs.length === 0, erreurs.slice(0, 3));
    await capture(page, `fin_${nom.replace(/\W+/g, "_")}`);
    await browser.close();
  }
}

// ─── Parcours ────────────────────────────────────────────────────────────────

await parcours("accueil invité", async (page) => {
  const fermees = await entrerCommeInvite(page);
  r.verifier("récompense du jour proposée", fermees.includes("Récupérer"), fermees);
  // Le Sanctuaire n'expose pas ses chiffres à l'accessibilité (constat QA) :
  // on vérifie l'état serveur avec la session de l'app.
  const etat = await page.evaluate(async () => {
    const cle = Object.keys(localStorage).find((k) => k.includes("auth-token"));
    const token = JSON.parse(localStorage.getItem(cle) ?? "{}").access_token;
    const r = await fetch("http://127.0.0.1:54321/rest/v1/rpc/get_player_state", {
      method: "POST", headers: { apikey: token, Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: "{}",
    });
    return r.json();
  });
  r.verifier("Sanctuaire affiché", await voit(page, "Sanctuaire"));
  r.verifier("Q10 : niveau, PV et série lus par les lecteurs d'écran", await voit(page, "Niveau 1, 0 sur"));
  await capture(page, "sanctuaire_invite");
  r.verifier("accueil vide : bouton de création proposé", await voit(page, "Créer ma première quête"));
  r.verifier("état serveur : niveau 1, 30 or, 1 Sceau", etat?.stats?.level === 1 && etat?.stats?.gold === 30 && etat?.stats?.seals === 1, etat?.stats);
});

await parcours("quête déclarative", async (page) => {
  await entrerCommeInvite(page);
  await creerQuete(page, { titre: "Faire la vaisselle", difficulte: 2 });
  await toucher(page, "Faire la vaisselle");
  await toucher(page, "Valider la quête");          // fiche de la quête
  await toucher(page, "Valider la quête");          // page de validation
  await attendre(page, "Quête accomplie");
  const rec = await recompense(page, "Faire la vaisselle");
  // Difficulté 2 en déclaratif : 30 × 0,5 = 15 XP de base (bonus selon l'échéance).
  r.verifier("serveur : mode déclaratif, XP de base 15 ou plus", rec?.mode === "declaratif" && rec?.xp >= 15 && rec?.seals === 0, rec);
  // Les montants s'affichent avec un compteur animé : on attend la valeur finale.
  r.verifier("l'écran affiche l'XP du serveur", await attendre(page, `+${rec?.xp}`, 8000).catch(() => false), rec?.xp);
  r.verifier("l'écran affiche l'or du serveur", await attendre(page, `+${rec?.gold}`, 8000).catch(() => false), rec?.gold);
  await capture(page, "declarative_recompenses");
});

await parcours("oracle et défi de capture", async (page) => {
  await entrerCommeInvite(page);
  await creerQuete(page, { titre: "Ranger le bureau", difficulte: 2, photo: true, capturer: "quete_formulaire" });
  await pause(800);
  await capture(page, "quetes_liste");
  await toucher(page, "Ranger le bureau");
  await toucher(page, "Valider la quête");
  await attendre(page, "Défi de l'Oracle");
  r.verifier("pas de validation manuelle pour une quête photo", !(await voit(page, "Valider la quête")));
  r.verifier("défi affiché (écrit sur un papier)", await voit(page, "Écrit sur un papier"));
  await capture(page, "oracle_defi");

  // Ancienne photo : nette mais sans le défi.
  await prendrePhoto(page, "Prendre une photo", "ancienne.jpg");
  await toucher(page, "Soumettre à l");
  await attendre(page, "n'a pas vu le geste", 30000);
  r.verifier("ancienne photo refusée malgré un bon score", await voit(page, "90/100"));
  r.verifier("la quête n'est pas validée", !(await voit(page, "Quête accomplie")));
  await capture(page, "oracle_refus");
  await page.mouse.wheel(0, 900);
  await pause(800);
  await capture(page, "oracle_verdict_refus");

  // Vraie preuve avec le nouveau défi.
  r.verifier("refus expliqué par le défi (pas par la netteté)", await voit(page, "Défi non visible"));
  await page.mouse.wheel(0, 1200);
  await pause(800);
  // « Reprendre une photo » ouvre directement la caméra.
  await prendrePhoto(page, "Reprendre une photo", "preuve.jpg");
  await toucher(page, "Soumettre à l");
  await attendre(page, "Quête accomplie", 30000);
  const rec = await recompense(page, "Ranger le bureau");
  // Difficulté 2 prouvée : 30 XP de base pleins et 1 Sceau.
  r.verifier("serveur : validée par l'Oracle, XP pleine, 1 Sceau", rec?.mode === "oracle" && rec?.xp >= 30 && rec?.seals === 1, rec);
  r.verifier("l'écran affiche l'XP du serveur", await attendre(page, `+${rec?.xp}`, 8000).catch(() => false), rec?.xp);
  r.verifier("l'écran affiche les Sceaux gagnés", await voit(page, "Sceau"));
  await capture(page, "oracle_recompenses");
});

await parcours("photo sombre", async (page) => {
  await entrerCommeInvite(page);
  await creerQuete(page, { titre: "Arroser les plantes", difficulte: 1, photo: true });
  await toucher(page, "Arroser les plantes");
  await toucher(page, "Valider la quête");
  await attendre(page, "Défi de l'Oracle");
  await prendrePhoto(page, "Prendre une photo", "sombre.jpg");
  await toucher(page, "Soumettre à l");
  await attendre(page, "15/100", 30000);
  r.verifier("photo ratée refusée", !(await voit(page, "Quête accomplie")));
});

await parcours("quête par thème", async (page) => {
  await entrerCommeInvite(page);
  await toucher(page, "Quêtes");
  await attendre(page, "Terminées");
  await pause(800);
  await page.getByRole("button", { name: "Nouvelle quête" }).first().click({ timeout: 15000 });
  await toucher(page, "Par thème");
  await attendre(page, "Choisir un thème");
  await pause(600);
  await capture(page, "theme_choix");
  await toucher(page, "Maison");
  await attendre(page, "Ranger une pièce");
  await pause(600);
  await capture(page, "theme_liste");
  await toucher(page, "Ranger une pièce");
  // « Durée estimée » est fusionné dans le nœud du dialogue : on attend un choix.
  await toucher(page, "10 min", { exact: true });
  await pause(500);
  await capture(page, "theme_duree");
  await toucher(page, "Créer", { exact: true });
  // Retour direct à la liste (les deux écrans intermédiaires sont dépilés).
  r.verifier("quête par thème créée et visible", await attendre(page, "Ranger une pièce", 10000).catch(() => false));
  r.verifier("retour à la liste des quêtes", await attendre(page, "Terminées", 10000).catch(() => false));
  let quetes = null;
  for (let i = 0; i < 10 && !quetes?.length; i++) {
    quetes = (await api(page, "quests?select=title,estimated_duration_minutes")).data;
    if (!quetes?.length) await pause(500);
  }
  const creee = quetes?.find?.((q) => q.title === "Ranger une pièce");
  r.verifier("durée choisie enregistrée (10 min)", creee?.estimated_duration_minutes === 10, quetes);
});

await parcours("écrans pixel : calendrier, MougiBot, chat, profil, boutique", async (page) => {
  await entrerCommeInvite(page);
  await toucher(page, "Quêtes");
  await attendre(page, "Terminées");
  await pause(800);
  await page.getByRole("button", { name: "Calendrier" }).first().click({ timeout: 15000 });
  r.verifier("calendrier : semaine courante", await attendre(page, "Cette semaine", 10000).catch(() => false));
  r.verifier("calendrier : jour courant signalé", await voit(page, "Aujourd'hui"));
  await pause(600);
  await capture(page, "calendrier");
  await page.getByRole("button", { name: "Semaine suivante" }).first().click({ timeout: 15000 });
  r.verifier("calendrier : semaine suivante", await attendre(page, " au ", 5000).catch(() => false));
  await page.getByRole("button", { name: /Retour|Back/ }).first().click({ timeout: 15000 });
  await attendre(page, "Terminées");
  await pause(800);

  await page.getByRole("button", { name: "Nouvelle quête" }).first().click({ timeout: 15000 });
  await toucher(page, "Générer avec IA");
  await attendre(page, "Générer 3 quêtes");
  await pause(600);
  await capture(page, "mougibot_repos");
  await toucher(page, "Générer 3 quêtes");
  // Banc : l'IA est simulée ; on attend des idées ou un message d'erreur clair.
  const fini = await Promise.race([
    attendre(page, "Voici mes idées", 30000).then(() => "idees"),
    attendre(page, "rien trouvé", 30000).then(() => "erreur"),
  ]).catch(() => null);
  r.verifier("MougiBot répond (idées ou erreur lisible)", fini !== null, fini);
  await pause(800);
  await capture(page, "mougibot_resultat");

  await toucher(page, "Chat");
  r.verifier("page du chat affichée", await attendre(page, "Mon chat", 10000).catch(() => false));
  r.verifier("emplacements cosmétiques lisibles", await voit(page, "Chapeau"));
  await pause(800);
  await capture(page, "chat");

  await toucher(page, "Profil");
  r.verifier("profil : bandeau invité", await attendre(page, "Mode invité", 10000).catch(() => false));
  r.verifier("profil : niveau et XP lus", await voit(page, "Expérience 0 sur"));
  await pause(800);
  await capture(page, "profil");

  await toucher(page, "Portail");
  r.verifier("portail : soldes lus (or et Sceaux)", await attendre(page, "30 or", 10000).catch(() => false) && (await voit(page, "Sceaux")));
  await toucher(page, "Boutique", { exact: true });
  r.verifier("boutique : articles et prix", await attendre(page, "Acheter", 10000).catch(() => false) || (await voit(page, "Trop cher")));
  await pause(800);
  await capture(page, "boutique");
  await toucher(page, "Vendre", { exact: true });
  r.verifier("vente : inventaire vide expliqué", await attendre(page, "inventaire est vide", 10000).catch(() => false));
});

await parcours("lien profond vers une quête", async (page) => {
  await entrerCommeInvite(page);
  // Une quête créée ailleurs (notification, partage) s'ouvre par son lien.
  const { data } = await page.evaluate(async () => {
    const cle = Object.keys(localStorage).find((k) => k.includes("auth-token"));
    const session = JSON.parse(localStorage.getItem(cle) ?? "{}");
    const r = await fetch("http://127.0.0.1:54321/rest/v1/quests", {
      method: "POST",
      headers: { apikey: session.access_token, Authorization: `Bearer ${session.access_token}`,
                 "Content-Type": "application/json", Prefer: "return=representation" },
      body: JSON.stringify({ user_id: session.user.id, title: "Lire 20 pages", difficulty: 1, category: "Savoir", status: "active", validation_type: "photo" }),
    });
    return { data: await r.json() };
  });
  const id = data?.[0]?.id;
  r.verifier("quête créée par l'API", !!id, data);
  await page.goto(`http://127.0.0.1:8080/#/quete/${id}`);
  await attendre(page, "Défi de l'Oracle", 20000);
  r.verifier("le lien ouvre directement la validation de la quête", await voit(page, "Lire 20 pages"));
  await capture(page, "lien_profond");
  // Un lien inconnu ne casse rien.
  await page.goto("http://127.0.0.1:8080/#/quete/00000000-0000-0000-0000-000000000000");
  await attendre(page, "introuvable", 20000);
  r.verifier("quête inconnue : message clair", await voit(page, "introuvable"));
});

await parcours("invocation gratuite", async (page) => {
  await entrerCommeInvite(page);
  await toucher(page, "Portail", { exact: true });
  await attendre(page, "Invoquer · Gratuit");
  await pause(800);
  r.verifier("jauges de garantie à zéro pour un nouveau joueur", await voit(page, "Épique garanti dans 20 tirages") && await voit(page, "Légendaire garanti dans 80 tirages"));
  await capture(page, "portail_repos");
  await toucher(page, "Invoquer · Gratuit", { exact: true });
  // Séquence plein écran : charge du portail, puis révélation.
  await attendre(page, "Passer", 20000);
  await capture(page, "invocation_charge");
  // La charge ne dure que 1,8 s : si elle s'est achevée seule, rien à passer.
  await toucher(page, "Passer", { exact: true, timeout: 2500 }).catch(() => {});
  await attendre(page, "Continuer", 10000);
  await pause(1200);
  await capture(page, "invocation_revelation");
  const etat = await page.evaluate(async () => {
    const cle = Object.keys(localStorage).find((k) => k.includes("auth-token"));
    const token = JSON.parse(localStorage.getItem(cle) ?? "{}").access_token;
    const r = await fetch("http://127.0.0.1:54321/rest/v1/rpc/get_player_state", {
      method: "POST", headers: { apikey: token, Authorization: `Bearer ${token}`, "Content-Type": "application/json" }, body: "{}",
    });
    return r.json();
  });
  r.verifier("serveur : tirage gratuit du jour consommé", etat?.gacha?.objets?.free_available === false, etat?.gacha);
  r.verifier("serveur : aucun Sceau dépensé", etat?.stats?.seals === 1, etat?.stats);
  await toucher(page, "Continuer", { exact: true });
  await attendre(page, "Invoquer · 10 Sceaux", 10000);
  r.verifier("la jauge épique avance d'un tirage", await voit(page, "Épique garanti dans 19 tirages"));
  r.verifier("retour au portail après la révélation", !(await voit(page, "Passer")));
});

await parcours("triche depuis le navigateur", async (page) => {
  await entrerCommeInvite(page);
  // Un joueur malin réutilise la session de l'app pour écrire en direct.
  const res = await page.evaluate(async () => {
    const cle = Object.keys(localStorage).find((k) => k.includes("auth-token"));
    const session = JSON.parse(localStorage.getItem(cle) ?? "{}");
    const token = session.access_token;
    const uid = session.user?.id;
    const base = "http://127.0.0.1:54321/rest/v1";
    const apikey = token; // la passerelle du banc n'exige pas de clé distincte
    const ecrire = (table, body, filtre) => fetch(`${base}/${table}?${filtre}`, {
      method: "PATCH",
      headers: { apikey, Authorization: `Bearer ${token}`, "Content-Type": "application/json", Prefer: "return=representation" },
      body: JSON.stringify(body),
    }).then(async (r) => ({ status: r.status, body: await r.text() }));
    return {
      token: !!token,
      or: await ecrire("player_stats", { gold: 999999 }, `user_id=eq.${uid}`),
      energie: await ecrire("ai_validation_credits", { balance: 99 }, `user_id=eq.${uid}`),
      config: await ecrire("game_config", { value: [999, 999, 999, 999] }, "key=eq.quest.base_xp"),
    };
  });
  r.verifier("session récupérée", res.token);
  r.verifier("écriture directe de l'or refusée", res.or.status >= 400, res.or);
  r.verifier("écriture directe de l'énergie refusée", res.energie.status >= 400, res.energie);
  r.verifier("réglages de jeu non modifiables", res.config.status >= 400 || res.config.body === "[]", res.config);
});

process.exit(r.fin() ? 1 : 0);
