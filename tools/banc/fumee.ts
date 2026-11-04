// Test de fumée du banc, au niveau API (comme le ferait l'app) :
// inscription, état joueur, quête déclarative, défi + Oracle simulé, gacha,
// tentative de triche. Usage : deno run -A tools/banc/fumee.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";

const env = Object.fromEntries(
  (await Deno.readTextFile("/tmp/sameva-banc/banc.env")).trim().split("\n").map((l) => l.split(/=(.*)/s).slice(0, 2)),
);
const sb = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, { auth: { persistSession: false } });
let ok = 0, ko = 0;
const check = (name: string, cond: boolean, info?: unknown) => {
  if (cond) { ok++; console.log(`  ok   ${name}`); } else { ko++; console.log(`  ÉCHEC ${name}`, info ?? ""); }
};
const photo = async (gray: number) => {
  const img = new Image(320, 240).fill(Image.rgbaToColor(gray, gray, gray, 255));
  for (let i = 1; i <= 320; i += 7) img.setPixelAt(i, 120, Image.rgbaToColor(255 - gray, 0, 0, 255));
  return btoa(String.fromCharCode(...await img.encodeJPEG(90)));
};

const email = `fumee+${Date.now()}@sameva.test`;
const { data: signup, error: e1 } = await sb.auth.signUp({ email, password: "MotDePasse!123" });
check("inscription e-mail (GoTrue)", !e1 && !!signup.session, e1);
const uid = signup.user!.id;
await sb.from("users").insert({ id: uid, username: "fumee", display_name: "Fumée" });

const { data: state, error: e2 } = await sb.rpc("get_player_state");
check("get_player_state", !e2 && state.stats.level === 1, e2);
const { data: daily } = await sb.rpc("claim_daily");
check("claim_daily : première ouverture", daily?.first_today === true, daily);

const { error: e3 } = await sb.from("player_stats").update({ gold: 999999 }).eq("user_id", uid);
check("triche : écriture directe de l'or refusée", !!e3, e3);

const { data: q1, error: e4 } = await sb.from("quests").insert({
  user_id: uid, title: "Faire la vaisselle", difficulty: 2, category: "Maison", frequency: "one_off",
  rarity: "common", status: "active", validation_type: "manual", xp_reward: 9999,
}).select().single();
check("création de quête (récompense imposée par le serveur)", !e4 && q1.xp_reward === 30, e4 ?? q1);
const { data: r1, error: e5 } = await sb.rpc("complete_quest", { p_quest_id: q1.id });
check("validation déclarative : 15 XP, 20 or", !e5 && r1.xp === 15 && r1.gold === 20, e5 ?? r1);

const { data: q2 } = await sb.from("quests").insert({
  user_id: uid, title: "Ranger ma chambre", difficulty: 2, category: "Maison", frequency: "one_off",
  rarity: "common", status: "active", validation_type: "photo",
}).select().single();
const { error: e6 } = await sb.rpc("complete_quest", { p_quest_id: q2.id });
check("quête photo : voie déclarative fermée", e6?.message === "preuve_requise", e6);

const oracle = async (gray: number) => {
  const { data: ch } = await sb.rpc("oracle_challenge", { p_quest_id: q2.id });
  const { data, error } = await sb.functions.invoke("analyze-quest-proof", {
    body: { quest_id: q2.id, challenge_id: ch.challenge_id, image_base64: await photo(gray) },
  });
  return { ch, data, error };
};
const sombre = await oracle(20);
check("Oracle : photo sombre refusée", sombre.data?.accepted === false, sombre.error ?? sombre.data);
const ancienne = await oracle(240);
check("Oracle : « ancienne photo » sans défi refusée", ancienne.data?.accepted === false && ancienne.data?.challenge_ok === false, ancienne.error ?? ancienne.data);
const bonne = await oracle(128);
check("Oracle : preuve + défi acceptée et récompensée", bonne.data?.accepted === true && bonne.data?.rewards?.seals === 1, bonne.error ?? bonne.data);

const { data: inv, error: e7 } = await sb.rpc("invoke", { p_banner: "objets", p_count: 1, p_use_free: true });
check("gacha : tirage gratuit du jour", !e7 && inv.results.length === 1, e7);
const { error: e8 } = await sb.rpc("invoke", { p_banner: "objets", p_count: 1 });
check("gacha : sans 10 Sceaux, refusé", e8?.message === "solde_insuffisant", e8);

// MougiBot « suggester » : la clé anon publique ne suffit plus, et un échec de
// l'IA (pas de clé Anthropic sur le banc) rend la génération consommée.
const anonSeul = await fetch(`${env.SUPABASE_URL}/functions/v1/suggest-quests`, {
  method: "POST",
  headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`, "Content-Type": "application/json" },
  body: "{}",
});
await anonSeul.body?.cancel();
check("suggestions : clé anon seule refusée", anonSeul.status === 401, anonSeul.status);
const { error: e9 } = await sb.functions.invoke("suggest-quests", { body: { quest_count: 2 } });
const { data: quota } = await sb.from("player_stats").select("suggestions_count").eq("user_id", uid).single();
check("suggestions : échec de l'IA, génération rendue", !!e9 && quota?.suggestions_count === 0, { e9, quota });

const { data: led } = await sb.from("economy_ledger").select("resource, amount, reason");
check("registre lisible par le joueur", (led?.length ?? 0) >= 6, led?.length);

console.log(`\n${ok} réussis, ${ko} en échec`);
Deno.exit(ko ? 1 : 0);
