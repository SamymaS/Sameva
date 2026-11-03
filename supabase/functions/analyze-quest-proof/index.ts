// supabase/functions/analyze-quest-proof/index.ts
//
// Edge Function Oracle (Sprint 1 : version autoritaire).
// La logique est dans logic.ts ; ce fichier ne fait que brancher Supabase et
// Anthropic.
//
// Secrets requis (supabase secrets set) :
//   - ANTHROPIC_API_KEY
// Variables fournies automatiquement par Supabase :
//   - SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//
// Requête (POST, en-tête Authorization: Bearer <JWT utilisateur>) :
//   { "quest_id": "<uuid>", "challenge_id": "<uuid>", "image_base64": "<jpeg|png en base64>" }
//   challenge_id : défi de capture obtenu par l'app via la RPC oracle_challenge
//   juste avant d'ouvrir la caméra.
//
// Réponse 200 (verdict déjà appliqué en base) :
//   { "proof_id", "quest_id", "accepted", "score", "threshold", "explanation",
//     "challenge", "challenge_ok",
//     "rewards": null | { "xp", "gold", "seals", "crystals", ... } }
//
// Erreurs : { "error": "<code>" } avec 400 (defi_requis...), 401,
// 402 (energie_insuffisante), 404, 409 (photo_deja_utilisee, analyse_en_cours,
// quete_deja_cloturee, defi_invalide), 410 (defi_expire), 413,
// 429 (plafond_atteint), 502 (oracle_indisponible, énergie rendue).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  createHandler,
  buildUserMessage,
  ImageInfo,
  MOUGIBOT_SYSTEM_PROMPT,
  parseVerdict,
  Verdict,
  VisionUnavailableError,
  VisionUnparseableError,
} from "./logic.ts";
import { normalizeImage } from "./dhash.ts";

declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_API_VERSION = "2023-06-01";
const CLAUDE_MODEL = "claude-haiku-4-5-20251001";
const MAX_TOKENS = 400;
const REQUEST_TIMEOUT_MS = 25_000;

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const admin = createClient(supabaseUrl, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function getUserId(authorization: string): Promise<string | null> {
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) return null;
  return data.user.id;
}

async function callVision(
  image: ImageInfo,
  title: string,
  category: string,
  challengeRequired: boolean,
): Promise<Verdict> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) throw new VisionUnavailableError("ANTHROPIC_API_KEY manquante dans les secrets Supabase");

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": ANTHROPIC_API_VERSION,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        // Le prompt système est identique à chaque appel : mis en cache.
        system: [{ type: "text", text: MOUGIBOT_SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
        messages: [{
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: image.mediaType, data: image.base64 } },
            { type: "text", text: buildUserMessage(title, category, challengeRequired) },
          ],
        }],
      }),
      signal: controller.signal,
    });
  } catch (e) {
    if (e instanceof DOMException && e.name === "AbortError") {
      throw new VisionUnavailableError(`Timeout MougiBot après ${REQUEST_TIMEOUT_MS / 1000} s`);
    }
    throw new VisionUnavailableError(e instanceof Error ? e.message : String(e));
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    throw new VisionUnavailableError(`Anthropic HTTP ${response.status} : ${(await response.text()).slice(0, 300)}`);
  }
  const data = await response.json();
  const text = data?.content?.[0]?.text;
  if (typeof text !== "string") throw new VisionUnavailableError("Format de réponse Anthropic inattendu");
  try {
    return parseVerdict(text);
  } catch (e) {
    // Le modèle a répondu (appel facturé) mais pas au format attendu.
    throw new VisionUnparseableError(e instanceof Error ? e.message : String(e));
  }
}

// Banc d'essai local uniquement (voir simulation.ts) : Oracle déterministe.
async function visionForEnvironment() {
  const { simulationAllowed, simulatedVision } = await import("./simulation.ts");
  if (!simulationAllowed(Deno.env)) return callVision;
  console.warn("ORACLE EN MODE SIMULATION (banc d'essai local)");
  return simulatedVision(async (sha256) => {
    const { data } = await admin
      .from("quest_proofs")
      .select("challenge_id, oracle_challenges!inner(gesture_code, number_code)")
      .eq("image_sha256", sha256)
      .eq("status", "pending")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    const ch = (data as { oracle_challenges?: { gesture_code: string | null; number_code: string } } | null)
      ?.oracle_challenges;
    return ch ? { gesture: ch.gesture_code, number: ch.number_code } : null;
  });
}

Deno.serve(createHandler({
  getUserId,
  rpc: async (fn, args) => {
    const { data, error } = await admin.rpc(fn, args);
    return { data, error: error ? { message: error.message, details: error.details, code: error.code } : null };
  },
  callVision: await visionForEnvironment(),
  normalizeImage,
  model: CLAUDE_MODEL,
}));
