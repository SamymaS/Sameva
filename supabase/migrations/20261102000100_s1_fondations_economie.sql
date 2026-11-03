-- =============================================================================
-- Sprint 1 · 1/4 : fondations de l'économie serveur
-- =============================================================================
-- Contenu :
--   - schéma `private` (non exposé par PostgREST) pour la logique interne
--   - table `game_config` : tous les réglages d'équilibrage, modifiables sans
--     republier l'app
--   - nouvelles colonnes de `player_stats` (Sceaux, Poussière, XP cumulée,
--     fuseau horaire, état Épuisé, horodatages des règles quotidiennes)
--   - registre `economy_ledger` en ajout seul + fonctions d'écriture
--   - montée de niveau calculée côté serveur
--
-- Principe : le client lit, le serveur écrit. Aucune fonction de ce fichier
-- n'est appelable par `anon` ou `authenticated`.
-- =============================================================================

BEGIN;

-- ─── Schéma privé ────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM anon, authenticated;
GRANT USAGE ON SCHEMA private TO service_role;

-- Les fonctions créées dans `public` sont exécutables par PUBLIC par défaut.
-- On coupe ce comportement pour les fonctions à venir : chaque RPC devra
-- recevoir un GRANT explicite.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA private REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- ─── Réglages de jeu ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.game_config (
  key         text        PRIMARY KEY,
  value       jsonb       NOT NULL,
  description text        NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.game_config IS
  'Réglages d''équilibrage lus par les fonctions serveur. Lecture publique '
  '(l''app affiche taux et coûts), écriture réservée aux administrateurs.';

ALTER TABLE public.game_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "game_config_read" ON public.game_config;
CREATE POLICY "game_config_read" ON public.game_config
  FOR SELECT TO authenticated USING (true);
REVOKE ALL ON public.game_config FROM anon, authenticated;
GRANT SELECT ON public.game_config TO authenticated;

INSERT INTO public.game_config (key, value, description) VALUES
  ('quest.base_xp',            '[15, 30, 50, 80]',  'XP de base par difficulté 1 à 4'),
  ('quest.base_gold',          '[20, 40, 70, 110]', 'Or de base par difficulté 1 à 4'),
  ('quest.validation_factor',  '{"oracle": 1.0, "declaratif": 0.5}', 'Multiplicateur selon le mode de validation'),
  ('quest.min_age_minutes_declaratif', '10', 'Âge minimal d''une quête déclarative avant validation'),
  ('quest.daily_tiers',        '[{"upto": 5, "factor": 1.0, "xp_only": false}, {"upto": 10, "factor": 0.5, "xp_only": false}, {"upto": null, "factor": 0.1, "xp_only": true}]',
                               'Rendements décroissants selon le rang de la quête récompensée dans la journée'),
  ('quest.planning_bonus',     '{"min_hours": 8, "bonus": 0.10}', 'Bonus si la quête a été créée suffisamment tôt'),
  ('quest.deadline_bonus',     '0.10', 'Bonus si l''échéance fixée à la création est tenue'),
  ('quest.streak_bonus',       '[{"days": 30, "bonus": 0.20}, {"days": 7, "bonus": 0.10}]', 'Bonus de flamme (palier le plus haut atteint)'),
  ('quest.seals_oracle',       '[1, 1, 1, 2]', 'Sceaux par difficulté, quêtes prouvées uniquement'),
  ('quest.crystals_oracle',    '[0, 0, 0, 1]', 'Cristaux par difficulté, quêtes prouvées uniquement'),
  ('quest.heal_hp',            '5', 'PV rendus par quête validée'),
  ('quest.exhausted_factor',   '0.5', 'Multiplicateur appliqué à l''état Épuisé (PV à 0)'),
  ('quest.drop',               '{"base_percent": 10, "per_difficulty_percent": 4, "max_rarity": ["uncommon", "rare", "rare", "epic"]}',
                               'Chance de butin et rareté maximale par difficulté'),
  ('level.xp_factor',          '150', 'XP requise pour passer le niveau L = facteur × L'),
  ('level.crystals_factor',    '2', 'Cristaux offerts à la montée au niveau L = facteur × L'),
  ('level.hp_per_level',       '10', 'PV max gagnés par niveau'),
  ('oracle.threshold',         '70', 'Score minimal pour valider une preuve'),
  ('oracle.daily_energy',      '3', 'Énergie rechargée chaque jour (plancher)'),
  ('oracle.onboarding_energy', '5', 'Énergie offerte à la première connexion'),
  ('oracle.energy_cap',        '10', 'Énergie maximale stockable'),
  ('oracle.premium_daily_cap', '30', 'Analyses par jour pour un abonné (usage raisonnable)'),
  ('oracle.pending_timeout_seconds', '90', 'Durée après laquelle une analyse en cours est considérée abandonnée'),
  ('daily.login',              '{"gold": 30, "seals": 1}', 'Récompense de première ouverture du jour'),
  ('hp.regen_percent_per_hour','5', 'Régénération des PV en % des PV max par heure pleine'),
  ('hp.missed_per_difficulty', '10', 'PV perdus par quête manquée, × difficulté'),
  ('moral.missed',             '0.1', 'Moral perdu par quête manquée'),
  ('streak.milestones',        '[{"days": 7, "crystals": 5, "item_rarity": "common"}, {"days": 14, "crystals": 10, "item_rarity": "rare"}, {"days": 30, "crystals": 25, "item_rarity": "epic"}, {"days": 100, "crystals": 100, "item_rarity": "legendary"}]',
                               'Paliers de flamme'),
  ('gacha.rates',              '{"common": 60.0, "uncommon": 25.0, "rare": 10.0, "epic": 4.0, "legendary": 1.0, "mythic": 0.0}',
                               'Taux publiés des bannières standard, en %'),
  ('gacha.banners',            '{"objets": {"cost_seals": 10, "cost_seals_x10": 90, "free_daily": true}, "compagnons": {"cost_seals": 10, "cost_seals_x10": 90, "free_daily": false}}',
                               'Bannières ouvertes et leur coût en Sceaux'),
  ('gacha.pity',               '{"epic_every": 20, "legendary_at": 80, "soft_start": 60, "soft_step_percent": 6.0}',
                               'Garanties anti-malchance'),
  ('transitional.caps',        '{"vente_objet": {"resource": "gold", "daily_cap": 300}, "doublon": {"resource": "crystals", "daily_cap": 30, "per_pull": 5}, "potion_xp": {"resource": "xp", "daily_cap": 100}, "potion_pv": {"resource": "hp", "daily_cap": 100}, "potion_moral": {"resource": "moral", "daily_cap": 0.3}, "caresse_chat": {"resource": "moral", "daily_cap": 0.3}}',
                               'TRANSITOIRE (supprimé au Sprint 3) : gains issus de l''inventaire encore local, plafonnés par jour'),
  ('transitional.spend_reasons', '["marche_achat", "craft", "boutique_cristaux"]',
                               'TRANSITOIRE (supprimé au Sprint 3) : motifs de dépense acceptés')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION private.cfg(p_key text)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT value FROM public.game_config WHERE key = p_key
$$;

CREATE OR REPLACE FUNCTION private.cfg_num(p_key text)
RETURNS numeric
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (value #>> '{}')::numeric FROM public.game_config WHERE key = p_key
$$;

-- ─── player_stats : colonnes serveur ─────────────────────────────────────────

ALTER TABLE public.player_stats
  ADD COLUMN IF NOT EXISTS total_experience  bigint      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS seals             integer     NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stardust          integer     NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_exhausted      boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS timezone          text        NOT NULL DEFAULT 'Europe/Paris',
  ADD COLUMN IF NOT EXISTS last_daily_claim  date,
  ADD COLUMN IF NOT EXISTS last_streak_day   date,
  ADD COLUMN IF NOT EXISTS timezone_changed_at timestamptz,
  ADD COLUMN IF NOT EXISTS quests_created_on date,
  ADD COLUMN IF NOT EXISTS quests_created_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_hp_regen_at  timestamptz NOT NULL DEFAULT now();

-- Reprise de l'existant. Avant ce sprint, le client pouvait écrire n'importe
-- quelle valeur : on ramène d'abord tout dans des bornes valides, sinon les
-- contraintes ci-dessous feraient échouer la migration.
UPDATE public.player_stats SET
  level             = greatest(1, level),
  experience        = greatest(0, experience),
  gold              = greatest(0, gold),
  crystals          = greatest(0, crystals),
  max_health_points = greatest(1, max_health_points),
  health_points     = greatest(0, least(health_points, greatest(1, max_health_points))),
  moral             = greatest(0, least(1, moral)),
  last_streak_day   = (last_active_date AT TIME ZONE 'Europe/Paris')::date;

-- L'XP cumulée est reconstituée depuis le niveau (courbe 150 × L).
UPDATE public.player_stats
SET total_experience = experience + 75 * (level - 1) * level
WHERE total_experience = 0 AND (level > 1 OR experience > 0);

DO $$
BEGIN
  ALTER TABLE public.player_stats
    ADD CONSTRAINT player_stats_balances_non_negative
    CHECK (gold >= 0 AND crystals >= 0 AND seals >= 0 AND stardust >= 0
           AND experience >= 0 AND level >= 1);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TABLE public.player_stats
    ADD CONSTRAINT player_stats_hp_range
    CHECK (health_points BETWEEN 0 AND max_health_points);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ─── Registre économique ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.economy_ledger (
  id              bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id         uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resource        text        NOT NULL CHECK (resource IN
                    ('xp', 'gold', 'crystals', 'seals', 'stardust', 'energy', 'hp', 'moral')),
  amount          numeric     NOT NULL CHECK (amount <> 0),
  balance_after   numeric     NOT NULL,
  reason          text        NOT NULL,
  ref_type        text,
  ref_id          text,
  idempotency_key text,
  metadata        jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.economy_ledger IS
  'Registre en ajout seul de tous les mouvements de ressources. Source de vérité '
  'comptable : les soldes de player_stats en sont un cache. Jamais modifié, '
  'jamais supprimé (sauf cascade à la suppression du compte).';

CREATE UNIQUE INDEX IF NOT EXISTS economy_ledger_idempotency_idx
  ON public.economy_ledger (user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS economy_ledger_user_time_idx
  ON public.economy_ledger (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS economy_ledger_user_reason_idx
  ON public.economy_ledger (user_id, reason, created_at DESC);

ALTER TABLE public.economy_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ledger_select_own" ON public.economy_ledger;
CREATE POLICY "ledger_select_own" ON public.economy_ledger
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.economy_ledger FROM anon, authenticated, service_role;
GRANT SELECT ON public.economy_ledger TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.ledger_immutable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'registre_immuable',
    DETAIL = 'Le registre économique est en ajout seul.';
END;
$$;

DROP TRIGGER IF EXISTS economy_ledger_no_update ON public.economy_ledger;
CREATE TRIGGER economy_ledger_no_update
  BEFORE UPDATE ON public.economy_ledger
  FOR EACH ROW EXECUTE FUNCTION private.ledger_immutable();

-- Soldes d'ouverture : une ligne par ressource non nulle, pour que l'invariant
-- « solde = somme des mouvements » soit vrai dès le premier jour.
INSERT INTO public.economy_ledger (user_id, resource, amount, balance_after, reason, idempotency_key)
SELECT ps.user_id, r.resource, r.amount, r.amount, 'opening_balance', 'opening:' || r.resource
FROM public.player_stats ps
CROSS JOIN LATERAL (VALUES
  ('gold',     ps.gold::numeric),
  ('crystals', ps.crystals::numeric),
  ('xp',       ps.total_experience::numeric)
) AS r(resource, amount)
WHERE r.amount > 0
ON CONFLICT DO NOTHING;

INSERT INTO public.economy_ledger (user_id, resource, amount, balance_after, reason, idempotency_key)
SELECT user_id, 'energy', greatest(0, balance), greatest(0, balance), 'opening_balance', 'opening:energy'
FROM public.ai_validation_credits
WHERE balance > 0
ON CONFLICT DO NOTHING;
UPDATE public.ai_validation_credits SET balance = greatest(0, balance);

-- ─── Utilitaires joueur ──────────────────────────────────────────────────────

-- Lève une erreur métier lisible par le client (message = code stable).
CREATE OR REPLACE FUNCTION private.fail(p_code text, p_detail text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = p_code, DETAIL = coalesce(p_detail, p_code);
END;
$$;

CREATE OR REPLACE FUNCTION private.require_user()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    PERFORM private.fail('non_authentifie');
  END IF;
  RETURN v_uid;
END;
$$;

-- Crée la ligne de stats si besoin et la verrouille pour la transaction.
CREATE OR REPLACE FUNCTION private.lock_player(p_user uuid)
RETURNS public.player_stats
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_row public.player_stats;
BEGIN
  INSERT INTO public.player_stats (user_id) VALUES (p_user)
  ON CONFLICT (user_id) DO NOTHING;
  SELECT * INTO v_row FROM public.player_stats WHERE user_id = p_user FOR UPDATE;
  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION private.local_today(p_user uuid)
RETURNS date
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (now() AT TIME ZONE coalesce(
    (SELECT timezone FROM public.player_stats WHERE user_id = p_user), 'Europe/Paris'))::date
$$;

-- Début du jour local en timestamptz (pour compter les événements « aujourd'hui »).
CREATE OR REPLACE FUNCTION private.local_day_start(p_user uuid)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (private.local_today(p_user)::timestamp) AT TIME ZONE coalesce(
    (SELECT timezone FROM public.player_stats WHERE user_id = p_user), 'Europe/Paris')
$$;

CREATE OR REPLACE FUNCTION private.is_premium(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.premium_subscriptions
    WHERE user_id = p_user
      AND is_premium
      AND (premium_until IS NULL OR premium_until > now())
  )
$$;

-- ─── Écriture dans le registre ───────────────────────────────────────────────

-- Applique un mouvement sur une ressource « simple » (tout sauf l'XP) et
-- l'inscrit au registre. Retourne le montant réellement appliqué (les PV et
-- le moral sont bornés, donc le delta effectif peut être plus petit).
-- Idempotent : une clé déjà vue renvoie 0 sans rien modifier.
CREATE OR REPLACE FUNCTION private.ledger_apply(
  p_user       uuid,
  p_resource   text,
  p_amount     numeric,
  p_reason     text,
  p_ref_type   text DEFAULT NULL,
  p_ref_id     text DEFAULT NULL,
  p_idem       text DEFAULT NULL,
  p_meta       jsonb DEFAULT '{}'::jsonb
)
RETURNS numeric
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_stats   public.player_stats;
  v_old     numeric;
  v_new     numeric;
  v_applied numeric;
BEGIN
  IF p_amount IS NULL OR p_amount = 0 THEN
    RETURN 0;
  END IF;

  IF p_idem IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.economy_ledger
    WHERE user_id = p_user AND idempotency_key = p_idem
  ) THEN
    RETURN 0;
  END IF;

  IF p_resource = 'xp' THEN
    PERFORM private.fail('ressource_invalide', 'Utiliser private.grant_xp pour l''XP');
  END IF;

  v_stats := private.lock_player(p_user);

  IF p_resource = 'energy' THEN
    INSERT INTO public.ai_validation_credits (user_id, balance)
    VALUES (p_user, 0)
    ON CONFLICT (user_id) DO NOTHING;
    SELECT balance INTO v_old FROM public.ai_validation_credits
    WHERE user_id = p_user FOR UPDATE;
  ELSE
    v_old := CASE p_resource
      WHEN 'gold'     THEN v_stats.gold
      WHEN 'crystals' THEN v_stats.crystals
      WHEN 'seals'    THEN v_stats.seals
      WHEN 'stardust' THEN v_stats.stardust
      WHEN 'hp'       THEN v_stats.health_points
      WHEN 'moral'    THEN v_stats.moral
    END;
  END IF;

  IF v_old IS NULL THEN
    PERFORM private.fail('ressource_invalide', p_resource);
  END IF;

  v_new := v_old + p_amount;

  IF p_resource = 'hp' THEN
    v_new := greatest(0, least(v_stats.max_health_points, v_new));
  ELSIF p_resource = 'energy' AND p_amount > 0 AND p_reason <> 'oracle_refund' THEN
    -- Plafond de stockage : un gain ne fait jamais dépasser le plafond
    -- (un solde déjà au-dessus, hérité, n'est pas réduit ; un remboursement
    -- rend toujours ce qui a été pris).
    v_new := least(v_new, greatest(v_old, private.cfg_num('oracle.energy_cap')));
  ELSIF p_resource = 'moral' THEN
    v_new := greatest(0, least(1, v_new));
  ELSIF v_new < 0 THEN
    PERFORM private.fail('solde_insuffisant',
      format('%s : solde %s, demandé %s', p_resource, v_old, -p_amount));
  END IF;

  v_applied := v_new - v_old;
  IF v_applied = 0 THEN
    RETURN 0;
  END IF;

  IF p_resource = 'energy' THEN
    UPDATE public.ai_validation_credits SET balance = v_new::int WHERE user_id = p_user;
  ELSE
    UPDATE public.player_stats SET
      gold          = CASE WHEN p_resource = 'gold'     THEN v_new::int ELSE gold END,
      crystals      = CASE WHEN p_resource = 'crystals' THEN v_new::int ELSE crystals END,
      seals         = CASE WHEN p_resource = 'seals'    THEN v_new::int ELSE seals END,
      stardust      = CASE WHEN p_resource = 'stardust' THEN v_new::int ELSE stardust END,
      health_points = CASE WHEN p_resource = 'hp'       THEN v_new::int ELSE health_points END,
      moral         = CASE WHEN p_resource = 'moral'    THEN v_new::float ELSE moral END,
      is_exhausted  = CASE WHEN p_resource = 'hp' AND v_new = 0 THEN true ELSE is_exhausted END
    WHERE user_id = p_user;
  END IF;

  INSERT INTO public.economy_ledger
    (user_id, resource, amount, balance_after, reason, ref_type, ref_id, idempotency_key, metadata)
  VALUES
    (p_user, p_resource, v_applied, v_new, p_reason, p_ref_type, p_ref_id, p_idem, coalesce(p_meta, '{}'::jsonb));

  RETURN v_applied;
END;
$$;

-- Accorde de l'XP, gère les montées de niveau (PV max, cristaux) et inscrit
-- le tout au registre. Retourne {xp, levels_gained, level_up_crystals, level}.
CREATE OR REPLACE FUNCTION private.grant_xp(
  p_user     uuid,
  p_amount   integer,
  p_reason   text,
  p_ref_type text DEFAULT NULL,
  p_ref_id   text DEFAULT NULL,
  p_idem     text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_stats      public.player_stats;
  v_factor     integer := private.cfg_num('level.xp_factor')::int;
  v_hp_step    integer := private.cfg_num('level.hp_per_level')::int;
  v_cry_factor integer := private.cfg_num('level.crystals_factor')::int;
  v_level      integer;
  v_xp         integer;
  v_gained     integer := 0;
  v_crystals   integer := 0;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN jsonb_build_object('xp', 0, 'levels_gained', 0, 'level_up_crystals', 0);
  END IF;

  IF p_idem IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.economy_ledger WHERE user_id = p_user AND idempotency_key = p_idem
  ) THEN
    RETURN jsonb_build_object('xp', 0, 'levels_gained', 0, 'level_up_crystals', 0);
  END IF;

  v_stats := private.lock_player(p_user);
  v_level := v_stats.level;
  v_xp    := v_stats.experience + p_amount;

  WHILE v_xp >= v_factor * v_level LOOP
    v_xp := v_xp - v_factor * v_level;
    v_level := v_level + 1;
    v_gained := v_gained + 1;
    v_crystals := v_crystals + v_cry_factor * v_level;
  END LOOP;

  UPDATE public.player_stats SET
    experience        = v_xp,
    total_experience  = total_experience + p_amount,
    level             = v_level,
    max_health_points = max_health_points + v_gained * v_hp_step
  WHERE user_id = p_user;

  INSERT INTO public.economy_ledger
    (user_id, resource, amount, balance_after, reason, ref_type, ref_id, idempotency_key, metadata)
  VALUES
    (p_user, 'xp', p_amount, v_stats.total_experience + p_amount, p_reason, p_ref_type, p_ref_id, p_idem,
     jsonb_build_object('level_before', v_stats.level, 'level_after', v_level));

  IF v_crystals > 0 THEN
    PERFORM private.ledger_apply(p_user, 'crystals', v_crystals, 'level_up', 'level', v_level::text,
      NULL, jsonb_build_object('from', v_stats.level, 'to', v_level));
  END IF;

  RETURN jsonb_build_object(
    'xp', p_amount,
    'levels_gained', v_gained,
    'level_up_crystals', v_crystals,
    'level', v_level);
END;
$$;

-- Régénération des PV selon le temps écoulé (heures pleines uniquement).
CREATE OR REPLACE FUNCTION private.regen_hp(p_user uuid)
RETURNS integer
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_stats   public.player_stats := private.lock_player(p_user);
  v_hours   integer;
  v_amount  integer;
  v_applied numeric := 0;
BEGIN
  v_hours := floor(extract(epoch FROM now() - v_stats.last_hp_regen_at) / 3600)::int;
  IF v_hours < 1 THEN
    RETURN 0;
  END IF;

  v_amount := ceil(v_stats.max_health_points * private.cfg_num('hp.regen_percent_per_hour') / 100.0 * v_hours)::int;
  IF v_stats.health_points < v_stats.max_health_points THEN
    v_applied := private.ledger_apply(p_user, 'hp', v_amount, 'hp_regen', NULL, NULL, NULL,
      jsonb_build_object('hours', v_hours));
  END IF;

  UPDATE public.player_stats
  SET last_hp_regen_at = last_hp_regen_at + make_interval(hours => v_hours)
  WHERE user_id = p_user;

  RETURN v_applied::int;
END;
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;

COMMIT;
