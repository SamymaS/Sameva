// supabase/functions/delete-account/index.ts
//
// Edge Function Supabase — Suppression de compte utilisateur (RGPD / droit à l'effacement).
// Permet à un utilisateur authentifié de supprimer définitivement son propre compte.
//
// ─── ARCHITECTURE DE SÉCURITÉ ──────────────────────────────────────────────
//
//   verify_jwt ACTIVÉ (plateforme Supabase valide le JWT avant d'appeler la
//   fonction — ne pas déployer avec --no-verify-jwt).
//
//   Garde impérative : l'userId est extrait du JWT de l'appelant via
//   anon.auth.getUser(). Un utilisateur ne peut supprimer QUE son propre
//   compte (jwt.sub == cible). Aucun userId arbitraire n'est jamais accepté
//   depuis le body.
//
//   Le client service_role (supabaseAdmin) est utilisé uniquement côté serveur
//   pour les opérations destructives ; il n'est jamais exposé au client Flutter.
//
// ─── ORDRE DE SUPPRESSION FK-SAFE (dérivé de sameva-rgpd) ─────────────────
//
//   Étape 1 — DELETE public.quest_difficulty_audit WHERE user_id = userId
//     Table d'audit sans FK vers auth.users → jamais purgée par cascade.
//     Doit être traitée manuellement en premier.
//
//   Étape 2 — supabaseAdmin.auth.admin.deleteUser(userId)
//     Supprime auth.users → déclenche ON DELETE CASCADE sur les 9 tables :
//       public.users
//         ├── public.quests             (CASCADE via public.users)
//         ├── public.user_inventory     (CASCADE via public.users)
//         ├── public.user_equipment     (CASCADE via public.users)
//         ├── public.companions         (CASCADE via public.users)
//         └── public.transactions       (CASCADE via public.users)
//       public.player_stats             (CASCADE direct depuis auth.users)
//       public.ai_validation_credits    (CASCADE direct depuis auth.users)
//       public.premium_subscriptions    (CASCADE direct depuis auth.users)
//
// ─── VARIABLES D'ENVIRONNEMENT ─────────────────────────────────────────────
//
//   SUPABASE_URL              : injectée automatiquement par Supabase
//   SUPABASE_SERVICE_ROLE_KEY : injectée automatiquement par Supabase
//   SUPABASE_ANON_KEY         : injectée automatiquement par Supabase
//   (Aucun secret supplémentaire requis — pas d'API externe appelée)
//
// ─── DÉPLOIEMENT ──────────────────────────────────────────────────────────
//
//   supabase functions deploy delete-account
//   (verify_jwt activé → NE PAS ajouter --no-verify-jwt)
//
// ─── FORMAT DE RÉPONSE ─────────────────────────────────────────────────────
//
//   Succès (200) :
//   { "success": true, "steps": { "audit_deleted": true, "auth_user_deleted": true } }
//
//   Échec partiel (500) :
//   { "success": false, "steps": { "audit_deleted": true, "auth_user_deleted": false },
//     "error": "Description de l'erreur" }
//
//   Flux UI attendu après succès :
//   1. Purger les clés Hive per-user :
//        cats_list_$userId, ai_validation_$userId, has_onboarded_$userId, lastFreePullAt
//   2. Appeler AuthViewModel.signOut() → propage onSignedOut → reset des ViewModels
//   3. Rediriger vers LoginPage via _AuthGate

// Types pour l'exécution Deno (Supabase Edge Functions)
// Évite "Cannot find name 'Deno'" dans les IDE TypeScript classiques.
declare const Deno: {
  env: { get(key: string): string | undefined };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};

// ─── Imports ────────────────────────────────────────────────────────────────

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── CORS ───────────────────────────────────────────────────────────────────

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ─── Types ──────────────────────────────────────────────────────────────────

/** Statut de chaque étape de suppression — remonte à l'UI pour un feedback précis. */
interface DeletionSteps {
  /** Lignes de quest_difficulty_audit supprimées (table sans CASCADE). */
  audit_deleted: boolean;
  /** Compte auth.users supprimé, ce qui déclenche toutes les cascades. */
  auth_user_deleted: boolean;
}

interface SuccessResponse {
  success: true;
  steps: DeletionSteps;
}

interface PartialErrorResponse {
  success: false;
  steps: DeletionSteps;
  error: string;
}

type ApiResponse = SuccessResponse | PartialErrorResponse | { error: string };

// ─── Helper ─────────────────────────────────────────────────────────────────

function jsonResponse(body: ApiResponse, status = 200): Response {
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
  // CORS preflight — obligatoire pour Flutter Web
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Seul POST est accepté
  if (req.method !== "POST") {
    return jsonResponse({ error: "Méthode non autorisée. Utilisez POST." }, 405);
  }

  // ── Lecture des secrets injectés automatiquement par Supabase ─────────────

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !supabaseServiceRoleKey || !supabaseAnonKey) {
    console.error(
      "Secrets Supabase manquants (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY ou SUPABASE_ANON_KEY)",
    );
    return jsonResponse({ error: "Configuration serveur incomplète" }, 500);
  }

  // ── GARDE DE SÉCURITÉ : extraction de l'userId depuis le JWT de l'appelant ─
  //
  // JAMAIS depuis le body — cela permettrait à quiconque d'effacer le compte
  // d'un autre utilisateur si la validation était absente ou contournée.
  // On extrait user.id du token JWT via auth.getUser(), qui valide le token
  // côté Supabase Auth et retourne le profil associé (jwt.sub).
  //
  // Le fait que verify_jwt soit activé au niveau plateforme garantit que les
  // requêtes sans JWT valide sont rejetées avant même d'atteindre ce code.
  // On appelle quand même auth.getUser() pour disposer de l'objet User complet.

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse(
      { error: "Authorization header manquant ou invalide" },
      401,
    );
  }

  // Client anon avec le JWT de l'appelant — on ne passe JAMAIS la service_role_key ici
  const supabaseAnon = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const {
    data: { user },
    error: authError,
  } = await supabaseAnon.auth.getUser();

  if (authError || !user) {
    console.error(
      "Échec auth.getUser() :",
      authError?.message ?? "utilisateur null",
    );
    return jsonResponse(
      { error: "Utilisateur non authentifié ou token invalide" },
      401,
    );
  }

  // userId extrait du JWT — seule valeur de confiance utilisée dans toutes
  // les opérations destructives qui suivent. Jamais remplacée par une valeur
  // issue du body ou d'un paramètre de requête.
  const userId: string = user.id;

  console.log(`Suppression de compte initiée pour user ${userId}`);

  // ── Client admin (service_role) — bypass RLS pour les opérations destructives ──
  //
  // SUPABASE_SERVICE_ROLE_KEY bypass la RLS Supabase et permet :
  //   - DELETE sur quest_difficulty_audit (policy service_role only)
  //   - auth.admin.deleteUser() (API Admin Auth — inaccessible aux clients anon)
  // Ce client ne quitte JAMAIS le serveur et n'est jamais loggué.

  const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false },
  });

  // ── Suivi de progression par étape ───────────────────────────────────────

  const steps: DeletionSteps = {
    audit_deleted: false,
    auth_user_deleted: false,
  };

  // ── ÉTAPE 1 : DELETE public.quest_difficulty_audit ───────────────────────
  //
  // Justification FK-safe : quest_difficulty_audit a été créée sans FK vers
  // auth.users (migration 20260512100000_quest_difficulty_check.sql, ligne 27).
  // La cascade déclenchée à l'étape 2 ne couvre PAS cette table.
  // Si on l'omettait, des lignes orphelines portant le user_id de l'utilisateur
  // supprimé resteraient indéfiniment en base — violation directe du droit
  // à l'effacement RGPD.
  //
  // On utilise le client service_role car la RLS est activée sur cette table
  // (migration 20260513120000_harden_rls_policies.sql, ligne 42) avec une seule
  // policy "audit_service_role_access" (service_role only — intentionnel).
  // Aucune policy DELETE n'existe pour le rôle authenticated.
  //
  // Un DELETE sur 0 lignes (utilisateur sans entrées d'audit) est un succès.

  try {
    const { error: auditDeleteError } = await supabaseAdmin
      .from("quest_difficulty_audit")
      .delete()
      .eq("user_id", userId);

    if (auditDeleteError) {
      throw new Error(
        `Erreur DELETE quest_difficulty_audit : ${auditDeleteError.message}`,
      );
    }

    steps.audit_deleted = true;
    console.log(`Étape 1 OK — quest_difficulty_audit purgée pour user ${userId}`);
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Étape 1 échouée :", message);

    // Arrêt ici : si la purge de l'audit échoue, on ne supprime pas auth.users.
    // Cela évite un état incohérent (compte supprimé mais lignes d'audit
    // orphelines non récupérables — l'utilisateur n'existant plus, la purge
    // deviendrait impossible sans intervention manuelle).
    return jsonResponse(
      {
        success: false,
        steps,
        error: `Étape 1 (purge audit) échouée : ${message}`,
      },
      500,
    );
  }

  // ── ÉTAPE 2 : supabaseAdmin.auth.admin.deleteUser(userId) ────────────────
  //
  // Supprime la ligne dans auth.users.
  // Déclenche ON DELETE CASCADE sur l'ensemble des tables couvertes :
  //
  //   auth.users
  //   ├── public.users (REFERENCES auth.users ON DELETE CASCADE)
  //   │   ├── public.quests             (REFERENCES public.users ON DELETE CASCADE)
  //   │   ├── public.user_inventory     (REFERENCES public.users ON DELETE CASCADE)
  //   │   ├── public.user_equipment     (PK user_id → public.users ON DELETE CASCADE)
  //   │   ├── public.companions         (REFERENCES public.users ON DELETE CASCADE)
  //   │   └── public.transactions       (REFERENCES public.users ON DELETE CASCADE)
  //   ├── public.player_stats           (PK user_id → auth.users ON DELETE CASCADE)
  //   ├── public.ai_validation_credits  (PK user_id → auth.users ON DELETE CASCADE)
  //   └── public.premium_subscriptions  (PK user_id → auth.users ON DELETE CASCADE)
  //
  // shouldSoftDelete = false → suppression définitive et immédiate.
  // Après cet appel, le JWT de l'utilisateur devient invalide côté Supabase Auth.

  try {
    const { error: deleteUserError } =
      await supabaseAdmin.auth.admin.deleteUser(
        userId,
        false, // shouldSoftDelete = false → effacement définitif, non réversible
      );

    if (deleteUserError) {
      throw new Error(
        `Erreur auth.admin.deleteUser : ${deleteUserError.message}`,
      );
    }

    steps.auth_user_deleted = true;
    console.log(
      `Étape 2 OK — auth.users supprimé pour user ${userId}. Cascades déclenchées sur 9 tables.`,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("Étape 2 échouée :", message);

    // État partiellement incohérent : l'audit est purgé (étape 1 OK) mais
    // le compte auth.users existe encore. Toutes les données Supabase
    // associées sont toujours présentes.
    // L'UI doit afficher une erreur et inviter à réessayer ou contacter le support.
    // Une seconde tentative de l'utilisateur re-tentera les deux étapes :
    // le DELETE de l'audit sur 0 lignes (déjà vide) réussira silencieusement,
    // puis deleteUser sera retentée.
    return jsonResponse(
      {
        success: false,
        steps,
        error: `Étape 2 (suppression compte auth) échouée : ${message}`,
      },
      500,
    );
  }

  // ── Succès complet ────────────────────────────────────────────────────────
  //
  // Toutes les données Supabase de l'utilisateur ont été supprimées.
  //
  // L'UI doit ensuite, côté Flutter :
  //   1. Purger les clés Hive per-user NON couvertes par _purgeHiveData() :
  //        box 'cats'         → clé 'cats_list_$userId'
  //        box 'aiValidation' → clé 'ai_validation_$userId'
  //        box 'settings'     → clé 'has_onboarded_$userId'
  //        box 'settings'     → clé 'lastFreePullAt'
  //   2. Appeler AuthViewModel.signOut()
  //        → propage onSignedOut vers PlayerViewModel, InventoryViewModel,
  //          EquipmentViewModel, CatViewModel, AiValidationCreditsService
  //        → reset des états mémoire
  //   3. _AuthGate détecte l'absence de session et redirige vers LoginPage

  console.log(`Suppression de compte RGPD complète pour user ${userId}`);
  return jsonResponse({ success: true, steps }, 200);
});
