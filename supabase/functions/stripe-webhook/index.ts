// supabase/functions/stripe-webhook/index.ts
//
// Edge Function Supabase — Réception et traitement des webhooks Stripe.
// Stripe appelle cet endpoint pour notifier les événements d'abonnement.
//
// POINT DE SÉCURITÉ CRITIQUE :
//   La signature Stripe est vérifiée AVANT tout traitement, en utilisant le
//   RAW body (await req.text(), pas de JSON.parse avant la vérification).
//   Sans cette vérification, n'importe qui pourrait POSTer un faux événement
//   "abonnement validé" et s'octroyer le statut premium gratuitement,
//   annulant toute la sécurité serveur-autoritaire de la brique 6.
//
// Fonctionnement :
//   1. Lit le body BRUT (req.text()) pour la vérification de signature.
//   2. Vérifie la signature via stripe.webhooks.constructEventAsync()
//      (version async requise par le runtime Deno — crypto async).
//   3. Si signature invalide → 400 immédiat, aucun traitement.
//   4. Traite les événements Stripe et met à jour premium_subscriptions
//      via un client Supabase en mode service_role (bypass RLS).
//   5. Retourne 200 rapidement (même pour les events non gérés) pour
//      éviter les retries Stripe inutiles.
//
// Idempotence : un même event rejoué ne casse rien (upsert sur user_id).
//
// Sécurité :
//   - verify_jwt = false  →  Stripe appelle sans JWT Supabase.
//     L'authentification se fait UNIQUEMENT via la signature Stripe.
//   - Le client Supabase utilise la SERVICE_ROLE_KEY pour bypasser la RLS
//     (seul chemin d'écriture autorisé sur premium_subscriptions).
//
// Variables d'environnement requises (via `supabase secrets set`) :
//   - STRIPE_SECRET_KEY      : clé secrète Stripe (sk_test_... en mode test)
//   - STRIPE_WEBHOOK_SECRET  : secret de signature du webhook (whsec_...)
//   Les variables SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont injectées
//   automatiquement par la plateforme Supabase.
//
// Déploiement (verify_jwt = false obligatoire pour que Stripe puisse appeler) :
//   supabase functions deploy stripe-webhook --no-verify-jwt
//
// Événements gérés :
//   - checkout.session.completed        → activation premium
//   - customer.subscription.updated     → mise à jour statut premium
//   - customer.subscription.deleted     → désactivation premium
//
// Enregistrement côté Stripe (à faire dans le dashboard Stripe) :
//   Endpoint URL : https://mgddxrysvjlpfejbmfly.supabase.co/functions/v1/stripe-webhook
//   Événements à sélectionner :
//     checkout.session.completed
//     customer.subscription.updated
//     customer.subscription.deleted

// Types pour l'exécution Deno (Supabase Edge Functions)
declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};

// ─── Imports ────────────────────────────────────────────────────────────────

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";

// ─── Types internes ──────────────────────────────────────────────────────────

/** Données à upsert dans premium_subscriptions. */
interface PremiumUpdate {
  user_id: string;
  is_premium: boolean;
  premium_until: string | null; // ISO 8601 ou null
  stripe_customer_id?: string;
  stripe_subscription_id?: string;
  updated_at: string; // ISO 8601
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Retourne une réponse JSON simple avec les headers minimaux. */
function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * Convertit un timestamp Unix Stripe (secondes) en chaîne ISO 8601.
 * Retourne null si la valeur est absente ou nulle.
 */
function unixToIso(ts: number | null | undefined): string | null {
  if (!ts) return null;
  return new Date(ts * 1000).toISOString();
}

/**
 * Détermine si un abonnement Stripe est considéré "actif" selon son statut.
 * - active / trialing → premium = true
 * - canceled / unpaid / past_due / paused / incomplete / incomplete_expired → premium = false
 * Logique documentée : on est strict — tout ce qui n'est pas explicitement "payé"
 * est considéré inactif. past_due laisse un délai de grâce côté Stripe (selon la config
 * retry), mais on coupe le premium immédiatement côté app pour rester serveur-autoritaire.
 */
function isSubscriptionActive(status: string): boolean {
  return status === "active" || status === "trialing";
}

// ─── Logique métier : mise à jour de premium_subscriptions ──────────────────

/**
 * Effectue un upsert sur premium_subscriptions via le client service_role.
 * L'opération est idempotente : si elle est rejouée avec les mêmes données,
 * le résultat est identique (upsert sur la clé primaire user_id).
 */
async function upsertPremiumSubscription(
  supabaseAdmin: ReturnType<typeof createClient>,
  update: PremiumUpdate,
): Promise<void> {
  const { error } = await supabaseAdmin
    .from("premium_subscriptions")
    .upsert(update, { onConflict: "user_id" });

  if (error) {
    throw new Error(
      `Erreur upsert premium_subscriptions (user: ${update.user_id}) : ${error.message}`,
    );
  }
}

// ─── Gestion des événements Stripe ──────────────────────────────────────────

/**
 * Traite l'événement checkout.session.completed.
 * Déclenché lorsqu'un utilisateur finalise le paiement sur Stripe Checkout.
 * On active immédiatement le premium avec la fin de période courante.
 */
async function handleCheckoutCompleted(
  supabaseAdmin: ReturnType<typeof createClient>,
  session: Stripe.Checkout.Session,
): Promise<void> {
  // Récupération du user_id : priorité à client_reference_id (champ officiel),
  // fallback sur metadata.user_id (champ explicite qu'on a ajouté à la création).
  const userId = session.client_reference_id ?? session.metadata?.user_id;
  if (!userId) {
    throw new Error(
      `checkout.session.completed sans user_id (session: ${session.id})`,
    );
  }

  const stripeCustomerId =
    typeof session.customer === "string"
      ? session.customer
      : session.customer?.id ?? null;

  const stripeSubscriptionId =
    typeof session.subscription === "string"
      ? session.subscription
      : session.subscription?.id ?? null;

  // Récupération de la date de fin de période depuis l'abonnement Stripe
  // (disponible si la session est en mode "subscription" et que l'abonnement
  // est immédiatement créé — ce qui est le cas en mode checkout standard).
  let premiumUntil: string | null = null;
  if (stripeSubscriptionId) {
    // Note : la subscription est souvent expandée dans la session, mais
    // si ce n'est pas le cas (objet non expand), on utilise null et le webhook
    // customer.subscription.updated qui suit mettra à jour premium_until.
    const sub = session.subscription;
    if (typeof sub === "object" && sub !== null) {
      premiumUntil = unixToIso((sub as Stripe.Subscription).current_period_end);
    }
  }

  await upsertPremiumSubscription(supabaseAdmin, {
    user_id: userId,
    is_premium: true,
    premium_until: premiumUntil,
    stripe_customer_id: stripeCustomerId ?? undefined,
    stripe_subscription_id: stripeSubscriptionId ?? undefined,
    updated_at: new Date().toISOString(),
  });

  console.log(
    `Premium activé pour user ${userId} (session: ${session.id}, ` +
    `customer: ${stripeCustomerId}, sub: ${stripeSubscriptionId}, ` +
    `until: ${premiumUntil})`,
  );
}

/**
 * Traite l'événement customer.subscription.updated.
 * Déclenché à chaque changement d'état de l'abonnement :
 * renouvellement, changement de plan, suspension, réactivation, etc.
 *
 * Pour retrouver le user_id, on cherche dans premium_subscriptions
 * par stripe_customer_id (relation stable Customer → User).
 */
async function handleSubscriptionUpdated(
  supabaseAdmin: ReturnType<typeof createClient>,
  subscription: Stripe.Subscription,
): Promise<void> {
  const stripeCustomerId =
    typeof subscription.customer === "string"
      ? subscription.customer
      : subscription.customer.id;

  // Recherche du user_id dans premium_subscriptions via le customer Stripe
  const { data: existing, error: lookupError } = await supabaseAdmin
    .from("premium_subscriptions")
    .select("user_id")
    .eq("stripe_customer_id", stripeCustomerId)
    .maybeSingle();

  if (lookupError) {
    throw new Error(
      `Erreur recherche user par customer ${stripeCustomerId} : ${lookupError.message}`,
    );
  }
  if (!existing?.user_id) {
    // Customer inconnu en base — peut arriver si checkout.session.completed
    // n'a pas encore été traité (cas de race condition ou event reçu hors-ordre).
    // On loggue mais on ne lève pas d'erreur pour ne pas bloquer les retries.
    console.warn(
      `customer.subscription.updated : customer ${stripeCustomerId} inconnu en base. ` +
      `Event ignoré (sera résolu par checkout.session.completed).`,
    );
    return;
  }

  const isPremium = isSubscriptionActive(subscription.status);
  const premiumUntil = isPremium
    ? unixToIso(subscription.current_period_end)
    : null;

  await upsertPremiumSubscription(supabaseAdmin, {
    user_id: existing.user_id,
    is_premium: isPremium,
    premium_until: premiumUntil,
    stripe_customer_id: stripeCustomerId,
    stripe_subscription_id: subscription.id,
    updated_at: new Date().toISOString(),
  });

  console.log(
    `Abonnement mis à jour pour user ${existing.user_id} ` +
    `(status: ${subscription.status}, premium: ${isPremium}, until: ${premiumUntil})`,
  );
}

/**
 * Traite l'événement customer.subscription.deleted.
 * Déclenché quand l'abonnement est définitivement annulé (fin de période ou
 * annulation immédiate). On coupe le premium immédiatement.
 */
async function handleSubscriptionDeleted(
  supabaseAdmin: ReturnType<typeof createClient>,
  subscription: Stripe.Subscription,
): Promise<void> {
  const stripeCustomerId =
    typeof subscription.customer === "string"
      ? subscription.customer
      : subscription.customer.id;

  // Même logique de recherche que pour subscription.updated
  const { data: existing, error: lookupError } = await supabaseAdmin
    .from("premium_subscriptions")
    .select("user_id")
    .eq("stripe_customer_id", stripeCustomerId)
    .maybeSingle();

  if (lookupError) {
    throw new Error(
      `Erreur recherche user par customer ${stripeCustomerId} : ${lookupError.message}`,
    );
  }
  if (!existing?.user_id) {
    console.warn(
      `customer.subscription.deleted : customer ${stripeCustomerId} inconnu en base. ` +
      `Event ignoré.`,
    );
    return;
  }

  await upsertPremiumSubscription(supabaseAdmin, {
    user_id: existing.user_id,
    is_premium: false,
    premium_until: null,
    stripe_customer_id: stripeCustomerId,
    stripe_subscription_id: subscription.id,
    updated_at: new Date().toISOString(),
  });

  console.log(
    `Premium désactivé pour user ${existing.user_id} ` +
    `(abonnement ${subscription.id} supprimé)`,
  );
}

// ─── Handler HTTP ────────────────────────────────────────────────────────────

Deno.serve(async (req: Request): Promise<Response> => {
  // Seul POST est accepté — Stripe n'envoie que des POST.
  // Note : pas de gestion OPTIONS ici car verify_jwt = false et Stripe
  // ne fait pas de preflight CORS (appel serveur-à-serveur).
  if (req.method !== "POST") {
    return jsonResponse({ error: "Méthode non autorisée. Stripe utilise POST." }, 405);
  }

  // ── Lecture des secrets ────────────────────────────────────────────────────

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!stripeSecretKey || !stripeWebhookSecret) {
    console.error(
      "Secrets Stripe manquants (STRIPE_SECRET_KEY ou STRIPE_WEBHOOK_SECRET)",
    );
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    console.error("Secrets Supabase manquants");
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }

  // ── LECTURE DU RAW BODY — CRITIQUE POUR LA VÉRIFICATION DE SIGNATURE ─────
  //
  // Le raw body DOIT être lu AVANT toute autre opération sur le body.
  // Si on fait req.json() ou req.text() une deuxième fois, le stream est
  // épuisé et la lecture échoue silencieusement ou lève une erreur.
  //
  // La bibliothèque Stripe calcule le HMAC-SHA256 sur les octets EXACTS reçus.
  // Si on parse le JSON puis le re-sérialise (JSON.stringify), les espaces,
  // l'ordre des clés ou l'encodage peuvent différer → signature invalide.
  // DONC : on passe rawBody directement à constructEventAsync, sans transformation.

  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Erreur lecture body :", message);
    return jsonResponse({ error: "Impossible de lire le body" }, 400);
  }

  // ── VÉRIFICATION DE SIGNATURE STRIPE — POINT DE SÉCURITÉ NON NÉGOCIABLE ──
  //
  // constructEventAsync vérifie que le webhook provient bien de Stripe en
  // recalculant le HMAC-SHA256 du rawBody avec STRIPE_WEBHOOK_SECRET et en
  // comparant au header Stripe-Signature.
  //
  // On utilise constructEventAsync (version async) car le runtime Deno
  // implémente l'API Web Crypto en mode asynchrone.
  //
  // Si la signature est invalide (faux webhook, body modifié en transit,
  // secret incorrect) → HTTP 400 immédiat, aucune donnée n'est modifiée.

  const signatureHeader = req.headers.get("stripe-signature");
  if (!signatureHeader) {
    console.error("Header stripe-signature absent");
    return jsonResponse({ error: "Header stripe-signature manquant" }, 400);
  }

  const stripe = new Stripe(stripeSecretKey, {
    apiVersion: "2023-10-16",
    httpClient: Stripe.createFetchHttpClient(),
  });

  let event: Stripe.Event;
  try {
    // constructEventAsync : version async requise pour le runtime Deno.
    // rawBody est passé tel quel (string brut, pas JSON.parse).
    // signatureHeader est le header "Stripe-Signature" reçu tel quel.
    // stripeWebhookSecret est le secret HMAC récupéré depuis les secrets Supabase.
    event = await stripe.webhooks.constructEventAsync(
      rawBody,
      signatureHeader,
      stripeWebhookSecret,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    // Signature invalide : on loggue sans exposer le secret ni le payload.
    console.error("Signature Stripe invalide :", message);
    // HTTP 400 immédiat — Stripe interprétera ça comme un webhook rejeté.
    return jsonResponse({ error: "Signature Stripe invalide" }, 400);
  }

  // Signature valide — on peut maintenant traiter l'événement.

  // ── Client Supabase en mode service_role ───────────────────────────────────
  // Ce client bypass la RLS de premium_subscriptions.
  // Il ne doit jamais être exposé au client Flutter ni loggué.

  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  // ── Traitement de l'événement ─────────────────────────────────────────────

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        await handleCheckoutCompleted(supabaseAdmin, session);
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionUpdated(supabaseAdmin, subscription);
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        await handleSubscriptionDeleted(supabaseAdmin, subscription);
        break;
      }

      default:
        // Événement non géré — on retourne 200 immédiatement pour éviter
        // que Stripe le marque comme "échoué" et le rejoue indéfiniment.
        console.log(`Événement Stripe non géré (ignoré) : ${event.type}`);
        break;
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error(`Erreur traitement événement ${event.type} :`, message);
    // On retourne 500 pour que Stripe sache que le traitement a échoué
    // et puisse rejouer l'événement selon sa politique de retry.
    return jsonResponse(
      { error: "Erreur interne lors du traitement de l'événement" },
      500,
    );
  }

  // ── Réponse de confirmation à Stripe ─────────────────────────────────────
  // HTTP 200 + JSON léger — Stripe attend une réponse rapide (< 30 s).

  return jsonResponse({ received: true });
});
