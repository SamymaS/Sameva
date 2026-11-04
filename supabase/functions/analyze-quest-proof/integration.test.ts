// supabase/functions/analyze-quest-proof/integration.test.ts
//
// Test d'intégration : le vrai handler contre une vraie base Postgres portant
// les migrations Sameva (IA simulée). Ignoré si SAMEVA_TEST_DB_URL est absent.
//
// Exécution (base locale `supabase start`) :
//   SAMEVA_TEST_DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres \
//     deno test --node-modules-dir=none --allow-env --allow-net --allow-read --allow-sys \
//       supabase/functions/analyze-quest-proof/integration.test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import pg from "npm:pg@8.13.1";
import { createHandler, OracleDeps } from "./logic.ts";

const DB_URL = Deno.env.get("SAMEVA_TEST_DB_URL");
const JPEG = (seed: number) => btoa(String.fromCharCode(0xff, 0xd8, 0xff, 0xe0, seed, seed + 1, seed + 2));

Deno.test({
  name: "Oracle de bout en bout : rejet, panne, ancienne photo, acceptation, photo réutilisée",
  ignore: !DB_URL,
  fn: async () => {
    const db = new pg.Client({ connectionString: DB_URL });
    await db.connect();
    try {
      // Données de test (nettoyées par la cascade en fin de test).
      const user = (await db.query(
        "INSERT INTO auth.users (id, email) VALUES (gen_random_uuid(), 'oracle-it@test.fr') RETURNING id",
      )).rows[0].id as string;
      await db.query("SELECT private.lock_player($1)", [user]);
      await db.query("SELECT private.ledger_apply($1, 'energy', 3, 'test')", [user]);
      const quest = (await db.query(
        `INSERT INTO public.quests (user_id, title, difficulty, category, validation_type)
         VALUES ($1, 'Faire la vaisselle', 2, 'Maison', 'photo') RETURNING id`,
        [user],
      )).rows[0].id as string;

      let nextScore = 40;
      let showChallenge = true;          // la photo contient-elle le défi tiré ?
      let visionDown = false;
      let dhashSeed = 1000;
      let drawn: { gesture: string; number: string } = { gesture: "", number: "" };
      const deps: OracleDeps = {
        getUserId: async () => user,
        model: "modele-test",
        callVision: async () => {
          if (visionDown) throw new Error("Anthropic HTTP 529");
          // Le modèle simulé « voit » le défi seulement si la photo le contient.
          return showChallenge
            ? { score: nextScore, observedGesture: drawn.gesture, observedCode: drawn.number, explanation: "Verdict de test" }
            : { score: nextScore, observedGesture: null, observedCode: null, explanation: "Verdict de test" };
        },
        // Empreintes très éloignées les unes des autres (photos différentes).
        normalizeImage: async () => ({
          base64: "Tk9STQ==",
          dhash: String(BigInt(dhashSeed++) * 0x9e3779b97f4a7c15n % (1n << 62n)),
        }),
        rpc: async (fn, args) => {
          const names = Object.keys(args);
          const sql = `SELECT public.${fn}(${names.map((n, i) => `${n} => $${i + 1}`).join(", ")}) AS r`;
          try {
            await db.query("BEGIN");
            await db.query("SET LOCAL ROLE service_role");
            const res = await db.query(sql, names.map((n) => args[n]));
            await db.query("COMMIT");
            return { data: res.rows[0].r, error: null };
          } catch (e) {
            await db.query("ROLLBACK");
            const err = e as { message: string; detail?: string; code?: string };
            return { data: null, error: { message: err.message, details: err.detail, code: err.code } };
          }
        },
      };
      const handler = createHandler(deps);
      // Comme l'app : demander un défi (RPC utilisateur), puis envoyer la photo.
      const challengeFor = async (q: string) => {
        await db.query("BEGIN");
        await db.query("SELECT set_config('request.jwt.claims', $1, true)", [JSON.stringify({ sub: user, role: "authenticated" })]);
        await db.query("SET LOCAL ROLE authenticated");
        const id = (await db.query("SELECT public.oracle_challenge($1) ->> 'challenge_id' AS id", [q])).rows[0].id;
        await db.query("COMMIT");
        const row = (await db.query(
          "SELECT gesture_code, number_code FROM public.oracle_challenges WHERE id = $1", [id],
        )).rows[0];
        drawn = { gesture: row.gesture_code, number: row.number_code };
        return id as string;
      };
      const send = async (q: string, image: string) =>
        handler(new Request("http://x", {
          method: "POST",
          headers: { Authorization: "Bearer test" },
          body: JSON.stringify({ quest_id: q, challenge_id: await challengeFor(q), image_base64: image }),
        }));
      const call = (image: string) => send(quest, image);

      // 1. Score 40 : refus, énergie consommée, quête toujours active.
      let res = await call(JPEG(1));
      let body = await res.json();
      assertEquals([res.status, body.accepted, body.rewards], [200, false, null]);

      // 2. Panne de l'IA : 502, énergie rendue.
      visionDown = true;
      res = await call(JPEG(2));
      assertEquals([res.status, (await res.json()).refunded], [502, 1]);
      visionDown = false;

      // 3. Ancienne photo : excellente (95) mais sans le défi → refusée.
      nextScore = 95;
      showChallenge = false;
      res = await call(JPEG(4));
      body = await res.json();
      assertEquals([res.status, body.accepted, body.challenge_ok], [200, false, false]);
      showChallenge = true;

      // 4. Score 91 avec le défi : quête close et récompensée par le serveur.
      nextScore = 91;
      res = await call(JPEG(3));
      body = await res.json();
      assertEquals([res.status, body.accepted, body.rewards.xp, body.rewards.seals], [200, true, 30, 1]);

      const state = (await db.query(
        `SELECT q.status, q.validated_by, c.balance, ps.seals
         FROM public.quests q, public.ai_validation_credits c, public.player_stats ps
         WHERE q.id = $1 AND c.user_id = $2 AND ps.user_id = $2`,
        [quest, user],
      )).rows[0];
      // 3 énergie - refus (1) - panne remboursée (0) - ancienne photo (1) - acceptée (1) = 0
      assertEquals(state, { status: "completed", validated_by: "oracle", balance: 0, seals: 1 });

      // 5. Même photo sur une autre quête : refusée sans consommer d'énergie.
      const quest2 = (await db.query(
        `INSERT INTO public.quests (user_id, title, difficulty, category, validation_type)
         VALUES ($1, 'Autre', 1, 'Maison', 'photo') RETURNING id`,
        [user],
      )).rows[0].id as string;
      res = await send(quest2, JPEG(3));
      assertEquals([res.status, (await res.json()).error], [409, "photo_deja_utilisee"]);
      assertEquals((await db.query("SELECT balance FROM public.ai_validation_credits WHERE user_id = $1", [user])).rows[0].balance, 0);
    } finally {
      await db.query("DELETE FROM auth.users WHERE email = 'oracle-it@test.fr'");
      await db.end();
    }
  },
});
