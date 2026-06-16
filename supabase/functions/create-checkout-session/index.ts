// supabase/functions/create-checkout-session/index.ts
//
// Edge Function Supabase — Création d'une Stripe Checkout Session (mode abonnement).
// Appelée par l'app Flutter pour démarrer le tunnel de paiement Stripe.
//
// Fonctionnement :
//   1. Récupère l'identité de l'utilisateur via le JWT Supabase (Authorization header).
//   2. Crée ou récupère le customer Stripe associé à cet utilisateur.
//   3. Crée une Checkout Session Stripe en mode "subscription".
//   4. Retourne l'URL de la session au client Flutter qui l'ouvre dans un WebView.
//
// Sécurité :
//   - verify_jwt = true  →  seul un utilisateur connecté peut appeler cette fonction.
//   - La clé secrète Stripe n'est jamais exposée au client.
//
// Variables d'environnement requises (via `supabase secrets set`) :
//   - STRIPE_SECRET_KEY  : clé secrète Stripe (sk_test_... en mode test)
//   - STRIPE_PRICE_ID    : identifiant du prix d'abonnement Stripe (price_...)
//   Les variables SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont injectées
//   automatiquement par la plateforme Supabase.
//
// Déploiement (verify_jwt = true par défaut, pas de flag supplémentaire) :
//   supabase functions deploy create-checkout-session
//
// Format de requête (POST) :
//   Corps JSON vide accepté, ou {} — l'identité vient du JWT, pas du body.
//
// Format de réponse (200) :
//   { "url": "https://checkout.stripe.com/pay/cs_test_..." }
//
// Format d'erreur :
//   { "error": "description de l'erreur" }

// Types pour l'exécution Deno (Supabase Edge Functions)
declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};

// ─── Imports ────────────────────────────────────────────────────────────────

// SDK Supabase (client léger pour récupérer l'utilisateur via JWT)
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// SDK Stripe pour Deno (version officielle du CDN Stripe)
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

// ─── Configuration CORS ─────────────────────────────────────────────────────

// L'app Flutter utilise un WebView pour ouvrir l'URL Stripe — les appels API
// initiaux viennent du client Flutter via HTTPS, donc CORS est nécessaire
// pour les appels depuis le WebView ou depuis Chrome lors des tests.
const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Deep links de retour ────────────────────────────────────────────────────
// Le scheme "sameva://" correspond au custom URL scheme déclaré dans l'app
// Flutter (android/app/src/main/AndroidManifest.xml et ios/Runner/Info.plist).
// À confirmer avec Samy si le scheme exact est différent.
const SUCCESS_URL = "sameva://premium/success";
const CANCEL_URL = "sameva://premium/cancel";

// ─── Helpers ────────────────────────────────────────────────────────────────

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json",
    },
  });
}

// ─── Handler HTTP ────────────────────────────────────────────────────────────

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight — nécessaire pour les appels depuis WebView / navigateur
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Seul POST est accepté
  if (req.method !== "POST") {
    return jsonResponse({ error: "Méthode non autorisée. Utilisez POST." }, 405);
  }

  // ── Lecture des secrets ────────────────────────────────────────────────────

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  const stripePriceId = Deno.env.get("STRIPE_PRICE_ID");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!stripeSecretKey) {
    console.error("Secret manquant : STRIPE_SECRET_KEY");
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }
  if (!stripePriceId) {
    console.error("Secret manquant : STRIPE_PRICE_ID");
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.error("Secret manquant : SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY");
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }

  // ── Identification de l'utilisateur via le JWT Supabase ───────────────────
  // Le header Authorization: Bearer <jwt> est transmis par l'app Flutter.
  // verify_jwt = true garantit que la fonction n'est pas appelable sans JWT valide,
  // mais on récupère tout de même l'utilisateur explicitement pour avoir son user_id.

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "Header Authorization manquant" }, 401);
  }
  const jwt = authHeader.slice(7);

  // Client Supabase en mode "anon" avec le JWT de l'utilisateur pour le valider
  const supabaseClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await supabaseClient.auth.getUser(jwt);
  if (userError || !userData?.user) {
    console.error("JWT invalide ou utilisateur introuvable :", userError?.message);
    return jsonResponse({ error: "Utilisateur non authentifié" }, 401);
  }

  const userId = userData.user.id;
  const userEmail = userData.user.email;

  // ── Initialisation du client Stripe ───────────────────────────────────────

  const stripe = new Stripe(stripeSecretKey, {
    // La version API Stripe est figée pour éviter les breaking changes non maîtrisés
    apiVersion: "2023-10-16",
    // Pas de runtime Node.js — on est dans Deno
    httpClient: Stripe.createFetchHttpClient(),
  });

  // ── Récupération ou création du customer Stripe ───────────────────────────
  // On vérifie d'abord si un stripe_customer_id existe déjà en base pour cet
  // utilisateur (stocké lors d'un premier abonnement). Si oui, on le réutilise —
  // cela évite de créer des doublons Stripe et permet à Stripe de pré-remplir
  // les coordonnées de paiement si l'utilisateur a déjà payé.

  let stripeCustomerId: string | null = null;

  // Lecture en mode service_role pour bypasser la RLS (lecture directe de la table)
  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: existingSubscription } = await supabaseAdmin
    .from("premium_subscriptions")
    .select("stripe_customer_id")
    .eq("user_id", userId)
    .maybeSingle();

  if (existingSubscription?.stripe_customer_id) {
    // Customer existant — on vérifie qu'il est toujours valide côté Stripe
    stripeCustomerId = existingSubscription.stripe_customer_id;
    try {
      await stripe.customers.retrieve(stripeCustomerId);
    } catch {
      // Customer supprimé côté Stripe — on en créera un nouveau
      stripeCustomerId = null;
    }
  }

  if (!stripeCustomerId) {
    // Création d'un nouveau customer Stripe avec l'email de l'utilisateur
    const customer = await stripe.customers.create({
      email: userEmail ?? undefined,
      metadata: {
        // On stocke le user_id Supabase dans les metadata du customer Stripe
        // pour pouvoir retrouver l'utilisateur depuis le dashboard Stripe
        supabase_user_id: userId,
      },
    });
    stripeCustomerId = customer.id;
  }

  // ── Création de la Checkout Session Stripe ────────────────────────────────

  let session: Stripe.Checkout.Session;
  try {
    session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: stripeCustomerId,
      line_items: [
        {
          price: stripePriceId,
          quantity: 1,
        },
      ],
      // success_url et cancel_url sont les deep links de retour vers l'app Flutter.
      // Stripe redirige vers ces URLs après paiement ou annulation.
      success_url: SUCCESS_URL,
      cancel_url: CANCEL_URL,
      // client_reference_id + metadata.user_id : double mécanisme pour que le webhook
      // puisse retrouver l'utilisateur Supabase à partir de la session Stripe.
      // client_reference_id est l'identifiant de référence officiel Stripe.
      // metadata.user_id est un fallback lisible dans le dashboard.
      client_reference_id: userId,
      metadata: {
        user_id: userId,
      },
      // Langue de l'interface Stripe (Sameva est en français)
      locale: "fr",
      // Autoriser la promotion si Samy crée des codes promo Stripe plus tard
      allow_promotion_codes: true,
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Erreur création Checkout Session Stripe :", message);
    return jsonResponse(
      { error: "Impossible de créer la session de paiement", detail: message },
      502,
    );
  }

  if (!session.url) {
    console.error("Session Stripe créée sans URL :", session.id);
    return jsonResponse({ error: "URL de session Stripe absente" }, 502);
  }

  // ── Réponse au client Flutter ─────────────────────────────────────────────
  // L'app Flutter ouvre session.url dans un WebView ou InAppBrowser.
  // On retourne aussi l'id de session pour référence éventuelle côté client.

  return jsonResponse({
    url: session.url,
    session_id: session.id,
  });
});
