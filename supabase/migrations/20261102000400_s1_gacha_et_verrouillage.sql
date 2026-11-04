-- =============================================================================
-- Sprint 1 · 4/4 : gacha serveur, passerelles transitoires, verrouillage
-- =============================================================================
-- Contenu :
--   - gacha serveur : coût en Sceaux, tirage, pity persistée, historique
--   - RPC `get_player_state`, `set_timezone`
--   - passerelles TRANSITOIRES tant que l'inventaire reste local (Sprint 3) :
--       `spend` (débit seul) et `claim_transitional_reward` (gains plafonnés)
--   - révocation de toutes les écritures directes sur les données de jeu
--   - classement basé sur l'XP cumulée
-- =============================================================================

BEGIN;

-- ─── État gacha ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.gacha_state (
  user_id           uuid    NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  banner            text    NOT NULL,
  since_epic        integer NOT NULL DEFAULT 0 CHECK (since_epic >= 0),
  since_legendary   integer NOT NULL DEFAULT 0 CHECK (since_legendary >= 0),
  total_pulls       integer NOT NULL DEFAULT 0 CHECK (total_pulls >= 0),
  last_free_pull_on date,
  PRIMARY KEY (user_id, banner)
);

CREATE TABLE IF NOT EXISTS public.gacha_pulls (
  id         bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  banner     text        NOT NULL,
  rarity     text        NOT NULL,
  by_pity    boolean     NOT NULL DEFAULT false,
  free       boolean     NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS gacha_pulls_user_time_idx ON public.gacha_pulls (user_id, created_at DESC);

ALTER TABLE public.gacha_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gacha_pulls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gacha_state_select_own" ON public.gacha_state;
CREATE POLICY "gacha_state_select_own" ON public.gacha_state
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
DROP POLICY IF EXISTS "gacha_pulls_select_own" ON public.gacha_pulls;
CREATE POLICY "gacha_pulls_select_own" ON public.gacha_pulls
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.gacha_state, public.gacha_pulls FROM anon, authenticated;
GRANT SELECT ON public.gacha_state, public.gacha_pulls TO authenticated;

-- ─── RPC : invocation ────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.invoke(
  p_banner   text,
  p_count    integer DEFAULT 1,
  p_use_free boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user     uuid := private.require_user();
  v_banner   jsonb := private.cfg('gacha.banners') -> p_banner;
  v_pity     jsonb := private.cfg('gacha.pity');
  v_base     jsonb := private.cfg('gacha.rates');
  v_rates    jsonb;
  v_state    public.gacha_state;
  v_today    date;
  v_cost     integer := 0;
  v_results  jsonb := '[]'::jsonb;
  v_rarity   text;
  v_by_pity  boolean;
  v_bonus    numeric;
  i          integer;
BEGIN
  IF v_banner IS NULL THEN
    PERFORM private.fail('banniere_inconnue', p_banner);
  END IF;
  IF p_count NOT IN (1, 10) THEN
    PERFORM private.fail('nombre_invalide', 'Une ou dix invocations.');
  END IF;

  PERFORM private.lock_player(v_user);
  v_today := private.local_today(v_user);

  INSERT INTO public.gacha_state (user_id, banner) VALUES (v_user, p_banner)
  ON CONFLICT (user_id, banner) DO NOTHING;
  SELECT * INTO v_state FROM public.gacha_state
  WHERE user_id = v_user AND banner = p_banner FOR UPDATE;

  IF p_use_free THEN
    IF p_count <> 1 OR NOT coalesce((v_banner ->> 'free_daily')::boolean, false) THEN
      PERFORM private.fail('gratuit_indisponible');
    END IF;
    -- Monotone : on ne revient jamais sur un jour déjà utilisé.
    IF v_state.last_free_pull_on IS NOT NULL AND v_state.last_free_pull_on >= v_today THEN
      PERFORM private.fail('gratuit_deja_utilise');
    END IF;
    v_state.last_free_pull_on := v_today;
  ELSE
    v_cost := CASE WHEN p_count = 1 THEN (v_banner ->> 'cost_seals')::int
                   ELSE (v_banner ->> 'cost_seals_x10')::int END;
    PERFORM private.ledger_apply(v_user, 'seals', -v_cost, 'gacha_pull', 'banner', p_banner, NULL,
      jsonb_build_object('count', p_count));
  END IF;

  FOR i IN 1..p_count LOOP
    v_state.since_epic      := v_state.since_epic + 1;
    v_state.since_legendary := v_state.since_legendary + 1;
    v_state.total_pulls     := v_state.total_pulls + 1;
    v_by_pity := false;
    v_rates := v_base;

    -- Pity douce : chaque tirage au-delà du seuil augmente le légendaire.
    IF v_state.since_legendary > (v_pity ->> 'soft_start')::int THEN
      v_bonus := least(
        (v_state.since_legendary - (v_pity ->> 'soft_start')::int) * (v_pity ->> 'soft_step_percent')::numeric,
        (v_base ->> 'common')::numeric);
      v_rates := jsonb_set(v_rates, '{legendary}', to_jsonb((v_base ->> 'legendary')::numeric + v_bonus));
      v_rates := jsonb_set(v_rates, '{common}',    to_jsonb((v_base ->> 'common')::numeric - v_bonus));
    END IF;

    v_rarity := private.roll_rarity(v_rates);

    -- Pity dure.
    IF v_state.since_legendary >= (v_pity ->> 'legendary_at')::int
       AND private.rarity_rank(v_rarity) < private.rarity_rank('legendary') THEN
      v_rarity := 'legendary';
      v_by_pity := true;
    ELSIF v_state.since_epic >= (v_pity ->> 'epic_every')::int
       AND private.rarity_rank(v_rarity) < private.rarity_rank('epic') THEN
      v_rarity := 'epic';
      v_by_pity := true;
    END IF;

    IF private.rarity_rank(v_rarity) >= private.rarity_rank('epic') THEN
      v_state.since_epic := 0;
    END IF;
    IF private.rarity_rank(v_rarity) >= private.rarity_rank('legendary') THEN
      v_state.since_legendary := 0;
    END IF;

    INSERT INTO public.gacha_pulls (user_id, banner, rarity, by_pity, free)
    VALUES (v_user, p_banner, v_rarity, v_by_pity, p_use_free);
    v_results := v_results || jsonb_build_array(jsonb_build_object('rarity', v_rarity, 'by_pity', v_by_pity));
  END LOOP;

  UPDATE public.gacha_state SET
    since_epic        = v_state.since_epic,
    since_legendary   = v_state.since_legendary,
    total_pulls       = v_state.total_pulls,
    last_free_pull_on = v_state.last_free_pull_on
  WHERE user_id = v_user AND banner = p_banner;

  RETURN jsonb_build_object(
    'banner',      p_banner,
    'results',     v_results,
    'seals_spent', v_cost,
    'free_used',   p_use_free,
    'pity', jsonb_build_object(
      'since_epic',          v_state.since_epic,
      'since_legendary',     v_state.since_legendary,
      'epic_guaranteed_in',  (v_pity ->> 'epic_every')::int - v_state.since_epic,
      'legendary_guaranteed_in', (v_pity ->> 'legendary_at')::int - v_state.since_legendary)
  );
END;
$$;

-- ─── RPC : état du joueur ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_player_state()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user   uuid := private.require_user();
  v_stats  public.player_stats;
  v_energy integer;
  v_today  date;
BEGIN
  v_stats := private.lock_player(v_user);
  INSERT INTO public.ai_validation_credits (user_id, balance) VALUES (v_user, 0)
  ON CONFLICT (user_id) DO NOTHING;
  SELECT balance INTO v_energy FROM public.ai_validation_credits WHERE user_id = v_user;
  v_today := private.local_today(v_user);

  RETURN jsonb_build_object(
    'stats',   to_jsonb(v_stats),
    'xp_for_next_level', private.cfg_num('level.xp_factor')::int * v_stats.level,
    'energy',  v_energy,
    'premium', private.is_premium(v_user),
    'today',   v_today,
    'gacha',   coalesce((
      SELECT jsonb_object_agg(banner, jsonb_build_object(
        'since_epic', since_epic,
        'since_legendary', since_legendary,
        'free_available', last_free_pull_on IS DISTINCT FROM v_today))
      FROM public.gacha_state WHERE user_id = v_user), '{}'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.set_timezone(p_timezone text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user  uuid := private.require_user();
  v_stats public.player_stats;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_timezone) THEN
    PERFORM private.fail('fuseau_invalide', p_timezone);
  END IF;
  v_stats := private.lock_player(v_user);
  IF v_stats.timezone = p_timezone THEN
    RETURN;
  END IF;
  -- Toutes les règles « par jour » dépendent du fuseau : il ne peut changer
  -- qu'une fois tous les 30 jours (un voyage reste possible, la triche non).
  IF v_stats.timezone_changed_at IS NOT NULL
     AND v_stats.timezone_changed_at > now() - interval '30 days' THEN
    PERFORM private.fail('fuseau_verrouille',
      format('Prochain changement possible le %s', (v_stats.timezone_changed_at + interval '30 days')::date));
  END IF;
  UPDATE public.player_stats SET timezone = p_timezone, timezone_changed_at = now() WHERE user_id = v_user;
END;
$$;

-- ─── Passerelles TRANSITOIRES (supprimées au Sprint 3) ───────────────────────

-- Débit seul : l'achat au marché, le craft et la boutique à cristaux restent
-- calculés par le client tant que le catalogue n'est pas en base. Un débit
-- ne peut jamais enrichir le joueur.
CREATE OR REPLACE FUNCTION public.spend(
  p_resource text,
  p_amount   integer,
  p_reason   text,
  p_ref      text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := private.require_user();
BEGIN
  IF p_resource NOT IN ('gold', 'crystals') THEN
    PERFORM private.fail('ressource_invalide', p_resource);
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    PERFORM private.fail('montant_invalide');
  END IF;
  IF NOT (private.cfg('transitional.spend_reasons') ? p_reason) THEN
    PERFORM private.fail('motif_invalide', p_reason);
  END IF;

  PERFORM private.ledger_apply(v_user, p_resource, -p_amount, 'spend:' || p_reason, 'item', p_ref);
  RETURN jsonb_build_object('resource', p_resource, 'spent', p_amount);
END;
$$;

-- Gains issus de l'inventaire local (vente, potions, doublons, caresses),
-- plafonnés par jour et par source. Le gain accordé peut être inférieur au
-- montant demandé : le client affiche ce que renvoie le serveur.
CREATE OR REPLACE FUNCTION public.claim_transitional_reward(
  p_source text,
  p_amount numeric,
  p_ref    text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user     uuid := private.require_user();
  v_cfg      jsonb := private.cfg('transitional.caps') -> p_source;
  v_resource text;
  v_cap      numeric;
  v_used     numeric;
  v_grant    numeric;
  v_applied  numeric;
BEGIN
  IF v_cfg IS NULL THEN
    PERFORM private.fail('source_invalide', p_source);
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    PERFORM private.fail('montant_invalide');
  END IF;

  v_resource := v_cfg ->> 'resource';
  v_cap := (v_cfg ->> 'daily_cap')::numeric;
  PERFORM private.lock_player(v_user);

  -- Remboursement de doublons : borné aussi par les tirages réellement faits
  -- aujourd'hui (pas de tirage, pas de doublon).
  IF v_cfg ? 'per_pull' THEN
    v_cap := least(v_cap, (v_cfg ->> 'per_pull')::numeric * (
      SELECT count(*) FROM public.gacha_pulls
      WHERE user_id = v_user AND created_at >= private.local_day_start(v_user)));
  END IF;

  SELECT coalesce(sum(amount), 0) INTO v_used FROM public.economy_ledger
  WHERE user_id = v_user AND reason = 'transitional:' || p_source
    AND created_at >= private.local_day_start(v_user);

  v_grant := least(p_amount, greatest(0, v_cap - v_used));
  IF v_resource IN ('gold', 'crystals', 'xp', 'hp') THEN
    v_grant := floor(v_grant);
  END IF;
  IF v_grant <= 0 THEN
    RETURN jsonb_build_object('resource', v_resource, 'granted', 0, 'capped', true);
  END IF;

  IF v_resource = 'xp' THEN
    v_applied := (private.grant_xp(v_user, v_grant::int, 'transitional:' || p_source, 'item', p_ref) ->> 'xp')::numeric;
  ELSE
    v_applied := private.ledger_apply(v_user, v_resource, v_grant, 'transitional:' || p_source, 'item', p_ref);
  END IF;

  RETURN jsonb_build_object(
    'resource', v_resource,
    'granted',  v_applied,
    'capped',   v_grant < p_amount);
END;
$$;

-- ─── Verrouillage des écritures directes ─────────────────────────────────────

-- player_stats : lecture seule pour le client.
DROP POLICY IF EXISTS "player_stats_self_access" ON public.player_stats;
DROP POLICY IF EXISTS "player_stats_select_own" ON public.player_stats;
CREATE POLICY "player_stats_select_own" ON public.player_stats
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.player_stats FROM anon, authenticated;
GRANT SELECT ON public.player_stats TO authenticated;

-- ai_validation_credits : lecture seule pour le client.
DROP POLICY IF EXISTS "ai_credits_insert_own" ON public.ai_validation_credits;
DROP POLICY IF EXISTS "ai_credits_update_own" ON public.ai_validation_credits;
REVOKE ALL ON public.ai_validation_credits FROM anon, authenticated;
GRANT SELECT ON public.ai_validation_credits TO authenticated;

-- quests : écritures gardées par les triggers du fichier 2/4.
REVOKE ALL ON public.quests FROM anon;
REVOKE TRUNCATE, REFERENCES, TRIGGER ON public.quests FROM authenticated;

-- premium_subscriptions : lecture seule (déjà le cas, réaffirmé).
REVOKE ALL ON public.premium_subscriptions FROM anon, authenticated;
GRANT SELECT ON public.premium_subscriptions TO authenticated;

-- transactions : table héritée sans usage, plus d'insertion client.
DROP POLICY IF EXISTS "transactions_insert_own" ON public.transactions;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.transactions FROM anon, authenticated;

-- quest_difficulty_audit : jamais exposée.
REVOKE ALL ON public.quest_difficulty_audit FROM anon, authenticated;

-- ─── Classement : XP cumulée ─────────────────────────────────────────────────

DROP VIEW IF EXISTS public.leaderboard_view;
CREATE VIEW public.leaderboard_view
  WITH (security_barrier = true, security_invoker = false) AS
  SELECT
    ps.user_id,
    ps.level,
    ps.total_experience AS xp,
    ps.streak,
    COALESCE(u.display_name, u.username, 'Aventurier') AS display_name
  FROM public.player_stats ps
  JOIN public.users u ON u.id = ps.user_id;
REVOKE ALL ON public.leaderboard_view FROM anon, authenticated;
GRANT SELECT ON public.leaderboard_view TO authenticated;
COMMENT ON VIEW public.leaderboard_view IS
  'Classement public. Bypass volontaire des RLS (security_invoker = false) limité '
  'à 5 colonnes publiques. Depuis le Sprint 1, xp = XP cumulée calculée par le '
  'serveur : le classement n''est plus falsifiable par le client.';

-- ─── Droits d'exécution des RPC ──────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.invoke(text, integer, boolean)                    FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_player_state()                               FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_timezone(text)                               FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.spend(text, integer, text, text)                 FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.claim_transitional_reward(text, numeric, text)   FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.invoke(text, integer, boolean)                  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_player_state()                             TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_timezone(text)                             TO authenticated;
GRANT EXECUTE ON FUNCTION public.spend(text, integer, text, text)               TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_transitional_reward(text, numeric, text) TO authenticated;

-- Fonctions héritées : jamais appelables par le client.
REVOKE ALL ON FUNCTION public.update_player_stats_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.update_updated_at_column()        FROM PUBLIC, anon, authenticated;

COMMIT;
