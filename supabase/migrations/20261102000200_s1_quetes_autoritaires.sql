-- =============================================================================
-- Sprint 1 · 2/4 : quêtes autoritaires
-- =============================================================================
-- Contenu :
--   - machine à états des quêtes : active → completed | failed (jamais supprimée)
--   - garde-fous à l'insertion et à la modification par le client
--   - calcul serveur des récompenses (formule R = base × V × P × S × K × E)
--   - RPC `complete_quest` (validation déclarative) et `claim_daily`
--     (règles quotidiennes : quêtes manquées, flamme, PV, énergie, connexion)
-- =============================================================================

BEGIN;

-- ─── Colonnes et contraintes ─────────────────────────────────────────────────

ALTER TABLE public.quests
  ADD COLUMN IF NOT EXISTS validated_by         text,
  ADD COLUMN IF NOT EXISTS rewarded_at          timestamptz,
  ADD COLUMN IF NOT EXISTS reward               jsonb,
  ADD COLUMN IF NOT EXISTS deadline_at_creation timestamptz,
  ADD COLUMN IF NOT EXISTS failed_at            timestamptz;

DO $$
BEGIN
  ALTER TABLE public.quests ADD CONSTRAINT quests_status_valid
    CHECK (status::text IN ('active', 'completed', 'failed', 'archived'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TABLE public.quests ADD CONSTRAINT quests_validation_type_valid
    CHECK (validation_type::text IN ('manual', 'photo', 'timer', 'geolocation', 'ai'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER TABLE public.quests ADD CONSTRAINT quests_validated_by_valid
    CHECK (validated_by IS NULL OR validated_by IN ('oracle', 'declaratif'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Une quête récompensée l'est une seule fois, et porte toujours son mode.
DO $$
BEGIN
  ALTER TABLE public.quests ADD CONSTRAINT quests_reward_consistency
    CHECK ((rewarded_at IS NULL) = (validated_by IS NULL));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS quests_user_rewarded_idx
  ON public.quests (user_id, rewarded_at DESC) WHERE rewarded_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS quests_user_active_deadline_idx
  ON public.quests (user_id, deadline) WHERE status = 'active';

INSERT INTO public.game_config (key, value, description) VALUES
  ('quest.max_created_per_day', '50', 'Nombre maximal de quêtes créées par jour (anti-spam, suppressions comprises)'),
  ('quest.edit_window_minutes', '10', 'Durée pendant laquelle titre, catégorie, difficulté et mode de preuve restent modifiables'),
  ('quest.deadline_bonus_min_hours', '6', 'Écart minimal entre la création et l''échéance pour que tenir l''échéance rapporte un bonus')
ON CONFLICT (key) DO NOTHING;

-- Compteur de créations du jour, insensible aux suppressions. SECURITY
-- DEFINER car appelé depuis le trigger d'insertion qui s'exécute avec le rôle
-- du client, lequel n'a aucun droit d'écriture sur player_stats.
CREATE OR REPLACE FUNCTION private.count_quest_creation(p_user uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_today date;
  v_count integer;
BEGIN
  IF p_user IS DISTINCT FROM auth.uid() THEN
    PERFORM private.fail('non_authentifie');
  END IF;
  PERFORM private.lock_player(p_user);
  v_today := private.local_today(p_user);
  UPDATE public.player_stats SET
    quests_created_count = CASE WHEN quests_created_on = v_today THEN quests_created_count + 1 ELSE 1 END,
    quests_created_on    = v_today
  WHERE user_id = p_user
  RETURNING quests_created_count INTO v_count;
  RETURN v_count;
END;
$$;

-- ─── Garde-fous client ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION private.is_client_role()
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT current_user IN ('authenticated', 'anon')
$$;

CREATE OR REPLACE FUNCTION private.expected_reward(p_difficulty integer, p_kind text)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (private.cfg(CASE p_kind WHEN 'xp' THEN 'quest.base_xp' ELSE 'quest.base_gold' END)
          ->> (greatest(1, least(4, p_difficulty)) - 1))::int
$$;

-- À l'insertion par le client, tout ce qui touche à l'économie est imposé par
-- le serveur, quelles que soient les valeurs envoyées.
CREATE OR REPLACE FUNCTION private.quests_before_insert()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NOT private.is_client_role() THEN
    RETURN NEW;
  END IF;

  IF NEW.category = 'boss' THEN
    PERFORM private.fail('categorie_reservee', 'Les boss sont créés par le serveur.');
  END IF;

  IF private.count_quest_creation(NEW.user_id) > private.cfg_num('quest.max_created_per_day') THEN
    PERFORM private.fail('plafond_atteint', 'Trop de quêtes créées aujourd''hui.');
  END IF;

  NEW.created_at           := now();
  NEW.updated_at           := now();
  NEW.status               := 'active';
  NEW.is_completed         := false;
  NEW.completed_at         := NULL;
  NEW.failed_at            := NULL;
  NEW.validated_by         := NULL;
  NEW.rewarded_at          := NULL;
  NEW.reward               := NULL;
  NEW.proof_data           := NULL;
  NEW.deadline_at_creation := NEW.deadline;
  NEW.xp_reward            := private.expected_reward(NEW.difficulty, 'xp');
  NEW.gold_reward          := private.expected_reward(NEW.difficulty, 'gold');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quests_guard_insert ON public.quests;
CREATE TRIGGER quests_guard_insert
  BEFORE INSERT ON public.quests
  FOR EACH ROW EXECUTE FUNCTION private.quests_before_insert();

-- À la modification par le client : le contenu d'une quête active reste
-- éditable, son cycle de vie et ses récompenses jamais.
CREATE OR REPLACE FUNCTION private.quests_before_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NOT private.is_client_role() THEN
    NEW.updated_at := now();
    RETURN NEW;
  END IF;

  IF NEW.status       IS DISTINCT FROM OLD.status
  OR NEW.is_completed IS DISTINCT FROM OLD.is_completed
  OR NEW.completed_at IS DISTINCT FROM OLD.completed_at
  OR NEW.proof_data   IS DISTINCT FROM OLD.proof_data
  OR NEW.user_id      IS DISTINCT FROM OLD.user_id
  OR NEW.id           IS DISTINCT FROM OLD.id THEN
    PERFORM private.fail('champ_protege',
      'Le statut d''une quête change uniquement via complete_quest ou l''Oracle.');
  END IF;

  IF OLD.status <> 'active' THEN
    PERFORM private.fail('quete_cloturee', 'Une quête terminée ou échouée n''est plus modifiable.');
  END IF;

  IF NEW.category = 'boss' AND OLD.category IS DISTINCT FROM 'boss' THEN
    PERFORM private.fail('categorie_reservee');
  END IF;

  -- Ce que l'Oracle juge et ce qui fixe la récompense se fige : après la
  -- fenêtre d'édition, ou dès qu'une preuve a été soumise.
  IF (NEW.title           IS DISTINCT FROM OLD.title
   OR NEW.category        IS DISTINCT FROM OLD.category
   OR NEW.difficulty      IS DISTINCT FROM OLD.difficulty
   OR NEW.validation_type IS DISTINCT FROM OLD.validation_type)
  AND (OLD.created_at < now() - make_interval(mins => private.cfg_num('quest.edit_window_minutes')::int)
       OR EXISTS (SELECT 1 FROM public.quest_proofs WHERE quest_id = OLD.id)) THEN
    PERFORM private.fail('champ_verrouille',
      'Titre, catégorie, difficulté et mode de preuve ne sont plus modifiables.');
  END IF;

  -- Une quête à preuve ne redevient jamais déclarative.
  IF OLD.validation_type::text IN ('photo', 'ai') AND NEW.validation_type::text NOT IN ('photo', 'ai') THEN
    PERFORM private.fail('champ_verrouille', 'Une quête à preuve ne peut pas devenir déclarative.');
  END IF;

  -- Une échéance peut être avancée, jamais repoussée ni retirée.
  IF OLD.deadline IS NOT NULL AND (NEW.deadline IS NULL OR NEW.deadline > OLD.deadline) THEN
    PERFORM private.fail('champ_verrouille', 'L''échéance ne peut pas être repoussée.');
  END IF;

  -- Valeurs silencieusement conservées ou recalculées.
  NEW.created_at           := OLD.created_at;
  NEW.updated_at           := now();
  NEW.failed_at            := OLD.failed_at;
  NEW.validated_by         := OLD.validated_by;
  NEW.rewarded_at          := OLD.rewarded_at;
  NEW.reward               := OLD.reward;
  NEW.deadline_at_creation := OLD.deadline_at_creation;
  NEW.xp_reward            := private.expected_reward(NEW.difficulty, 'xp');
  NEW.gold_reward          := private.expected_reward(NEW.difficulty, 'gold');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quests_guard_update ON public.quests;
CREATE TRIGGER quests_guard_update
  BEFORE UPDATE ON public.quests
  FOR EACH ROW EXECUTE FUNCTION private.quests_before_update();

-- Les quêtes terminées ou échouées sont de l'historique : seule une quête
-- active peut être supprimée par son auteur.
CREATE OR REPLACE FUNCTION private.quests_before_delete()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF private.is_client_role() AND OLD.deadline IS NOT NULL AND OLD.deadline < now() THEN
    PERFORM private.fail('quete_echue', 'Une quête dont l''échéance est passée ne peut plus être supprimée.');
  END IF;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS quests_guard_delete ON public.quests;
CREATE TRIGGER quests_guard_delete
  BEFORE DELETE ON public.quests
  FOR EACH ROW EXECUTE FUNCTION private.quests_before_delete();

DROP POLICY IF EXISTS "quests_delete_own" ON public.quests;
CREATE POLICY "quests_delete_own" ON public.quests
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id AND status = 'active');

-- ─── Calcul des récompenses ──────────────────────────────────────────────────

-- Rareté tirée selon les taux de `gacha.rates`, plafonnée à p_max_rarity.
CREATE OR REPLACE FUNCTION private.rarity_rank(p_rarity text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT array_position(ARRAY['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'], p_rarity)
$$;

CREATE OR REPLACE FUNCTION private.roll_rarity(p_rates jsonb, p_max_rarity text DEFAULT 'mythic')
RETURNS text
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_order text[] := ARRAY['mythic', 'legendary', 'epic', 'rare', 'uncommon', 'common'];
  v_roll  numeric := random() * 100;
  v_acc   numeric := 0;
  v_r     text;
  v_pick  text := 'common';
BEGIN
  FOREACH v_r IN ARRAY v_order LOOP
    v_acc := v_acc + coalesce((p_rates ->> v_r)::numeric, 0);
    IF v_roll < v_acc THEN
      v_pick := v_r;
      EXIT;
    END IF;
  END LOOP;
  IF private.rarity_rank(v_pick) > private.rarity_rank(p_max_rarity) THEN
    v_pick := p_max_rarity;
  END IF;
  RETURN v_pick;
END;
$$;

-- Termine une quête et distribue ses récompenses, en une seule transaction.
-- p_mode : 'oracle' (preuve validée) ou 'declaratif'.
CREATE OR REPLACE FUNCTION private.complete_quest(
  p_user     uuid,
  p_quest_id uuid,
  p_mode     text,
  p_proof_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_q            public.quests;
  v_stats        public.player_stats;
  v_today        date;
  v_last         date;
  v_streak       integer;
  v_streak_up    boolean := false;
  v_d            integer;
  v_v            numeric;
  v_p            numeric := 1;
  v_s            numeric := 1;
  v_k            numeric := 1;
  v_e            numeric := 1;
  v_xp_only      boolean := false;
  v_rank         integer;
  v_tier         jsonb;
  v_tier_item    jsonb;
  v_streak_tier  jsonb;
  v_planning     jsonb := private.cfg('quest.planning_bonus');
  v_xp           integer;
  v_gold         integer;
  v_seals        integer := 0;
  v_crystals     integer := 0;
  v_xp_result    jsonb;
  v_milestones   jsonb := '[]'::jsonb;
  v_milestone    jsonb;
  v_drop         jsonb := NULL;
  v_drop_cfg     jsonb := private.cfg('quest.drop');
  v_heal         numeric;
  v_level_before integer;
  v_result       jsonb;
  v_prefix       text;
BEGIN
  IF p_mode NOT IN ('oracle', 'declaratif') THEN
    PERFORM private.fail('mode_invalide', p_mode);
  END IF;

  -- Ordre de verrouillage commun à toutes les fonctions : joueur, puis quêtes.
  PERFORM private.lock_player(p_user);
  SELECT * INTO v_q FROM public.quests
  WHERE id = p_quest_id AND user_id = p_user
  FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.fail('quete_introuvable');
  END IF;
  IF v_q.status <> 'active' THEN
    PERFORM private.fail('quete_deja_cloturee');
  END IF;

  PERFORM private.regen_hp(p_user);
  v_stats := private.lock_player(p_user);
  v_level_before := v_stats.level;
  v_prefix := 'quest:' || p_quest_id::text || ':';

  -- Flamme : une journée compte dès la première quête validée. Le jour de
  -- référence est monotone (last_streak_day) : il ne recule jamais, même si
  -- le fuseau horaire change.
  v_today := private.local_today(p_user);
  v_last  := v_stats.last_streak_day;
  IF v_last IS NULL OR v_last < v_today - 1 THEN
    v_streak := 1;
    v_streak_up := true;
  ELSIF v_last = v_today - 1 THEN
    v_streak := v_stats.streak + 1;
    v_streak_up := true;
  ELSE
    v_streak := greatest(v_stats.streak, 1);
  END IF;

  -- Rang de la quête dans la journée (rendements décroissants).
  SELECT count(*) + 1 INTO v_rank
  FROM public.quests
  WHERE user_id = p_user AND rewarded_at >= private.local_day_start(p_user);

  FOR v_tier_item IN SELECT * FROM jsonb_array_elements(private.cfg('quest.daily_tiers')) LOOP
    IF v_tier_item ->> 'upto' IS NULL OR v_rank <= (v_tier_item ->> 'upto')::int THEN
      v_tier := v_tier_item;
      EXIT;
    END IF;
  END LOOP;
  v_k := (v_tier ->> 'factor')::numeric;
  v_xp_only := (v_tier ->> 'xp_only')::boolean;

  -- Facteurs.
  v_d := greatest(1, least(4, v_q.difficulty));
  v_v := (private.cfg('quest.validation_factor') ->> p_mode)::numeric;

  IF v_q.created_at <= now() - make_interval(hours => (v_planning ->> 'min_hours')::int) THEN
    v_p := v_p + (v_planning ->> 'bonus')::numeric;
  END IF;
  -- Bonus d'échéance : seulement pour un vrai engagement (échéance fixée au
  -- moins quelques heures après la création), sinon l'échéance par défaut
  -- « aujourd'hui 23:59 » le rendrait presque automatique.
  IF v_q.deadline_at_creation IS NOT NULL AND now() <= v_q.deadline_at_creation
     AND v_q.deadline_at_creation >= v_q.created_at
        + make_interval(hours => private.cfg_num('quest.deadline_bonus_min_hours')::int) THEN
    v_p := v_p + private.cfg_num('quest.deadline_bonus');
  END IF;

  FOR v_streak_tier IN SELECT * FROM jsonb_array_elements(private.cfg('quest.streak_bonus')) LOOP
    IF v_streak >= (v_streak_tier ->> 'days')::int THEN
      v_s := 1 + (v_streak_tier ->> 'bonus')::numeric;
      EXIT;
    END IF;
  END LOOP;

  IF v_stats.is_exhausted THEN
    v_e := private.cfg_num('quest.exhausted_factor');
  END IF;

  v_xp   := round(private.expected_reward(v_d, 'xp')   * v_v * v_p * v_s * v_k * v_e)::int;
  v_gold := CASE WHEN v_xp_only THEN 0
                 ELSE round(private.expected_reward(v_d, 'gold') * v_v * v_p * v_s * v_k * v_e)::int END;
  IF p_mode = 'oracle' AND NOT v_xp_only THEN
    v_seals    := (private.cfg('quest.seals_oracle')    ->> (v_d - 1))::int;
    v_crystals := (private.cfg('quest.crystals_oracle') ->> (v_d - 1))::int;
  END IF;

  -- Distribution.
  v_xp_result := private.grant_xp(p_user, v_xp, 'quest_reward', 'quest', p_quest_id::text, v_prefix || 'xp');
  PERFORM private.ledger_apply(p_user, 'gold',     v_gold,     'quest_reward', 'quest', p_quest_id::text, v_prefix || 'gold');
  PERFORM private.ledger_apply(p_user, 'seals',    v_seals,    'quest_reward', 'quest', p_quest_id::text, v_prefix || 'seals');
  PERFORM private.ledger_apply(p_user, 'crystals', v_crystals, 'quest_reward', 'quest', p_quest_id::text, v_prefix || 'crystals');
  v_heal := private.ledger_apply(p_user, 'hp', private.cfg_num('quest.heal_hp'), 'quest_heal', 'quest', p_quest_id::text, v_prefix || 'hp');

  UPDATE public.player_stats SET
    streak                 = v_streak,
    max_streak             = greatest(max_streak, v_streak),
    last_active_date       = now(),
    last_streak_day        = greatest(coalesce(last_streak_day, v_today), v_today),
    total_quests_completed = total_quests_completed + 1,
    is_exhausted           = CASE WHEN p_mode = 'oracle' THEN false ELSE is_exhausted END
  WHERE user_id = p_user;

  -- Paliers de flamme : une fois par série (la clé porte le jour de début de
  -- la série). Reconstruire une série après l'avoir perdue redonne le palier.
  IF v_streak_up THEN
    FOR v_milestone IN SELECT * FROM jsonb_array_elements(private.cfg('streak.milestones')) LOOP
      IF (v_milestone ->> 'days')::int = v_streak THEN
        PERFORM private.ledger_apply(p_user, 'crystals', (v_milestone ->> 'crystals')::int,
          'streak_milestone', 'streak', v_streak::text,
          'streak:' || v_streak || ':' || (v_today - (v_streak - 1))::text);
        v_milestones := v_milestones || jsonb_build_array(v_milestone);
      END IF;
    END LOOP;
  END IF;

  -- Butin (l'objet concret est encore matérialisé par le client jusqu'au Sprint 3).
  IF random() * 100 < (v_drop_cfg ->> 'base_percent')::numeric
                      + (v_drop_cfg ->> 'per_difficulty_percent')::numeric * v_d THEN
    v_drop := jsonb_build_object('rarity',
      private.roll_rarity(private.cfg('gacha.rates'), v_drop_cfg -> 'max_rarity' ->> (v_d - 1)));
  END IF;

  v_result := jsonb_build_object(
    'quest_id',          p_quest_id,
    'mode',              p_mode,
    'xp',                v_xp,
    'gold',              v_gold,
    'seals',             v_seals,
    'crystals',          v_crystals,
    'hp_healed',         v_heal,
    'level_before',      v_level_before,
    'level_after',       (v_xp_result ->> 'level')::int,
    'level_up_crystals', (v_xp_result ->> 'level_up_crystals')::int,
    'streak',            v_streak,
    'streak_milestones', v_milestones,
    'drop',              v_drop,
    'factors', jsonb_build_object(
      'validation', v_v, 'planning', v_p, 'streak', v_s,
      'daily_rank', v_rank, 'daily', v_k, 'exhausted', v_e),
    'proof_id',          p_proof_id
  );

  UPDATE public.quests SET
    status       = 'completed',
    is_completed = true,
    completed_at = now(),
    validated_by = p_mode,
    rewarded_at  = now(),
    reward       = v_result
  WHERE id = p_quest_id;

  RETURN v_result;
END;
$$;

-- ─── RPC : validation déclarative ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.complete_quest(p_quest_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := private.require_user();
  v_q    public.quests;
BEGIN
  SELECT * INTO v_q FROM public.quests WHERE id = p_quest_id AND user_id = v_user;
  IF NOT FOUND THEN
    PERFORM private.fail('quete_introuvable');
  END IF;
  IF v_q.status <> 'active' THEN
    PERFORM private.fail('quete_deja_cloturee');
  END IF;
  IF v_q.validation_type::text IN ('photo', 'ai') THEN
    PERFORM private.fail('preuve_requise', 'Cette quête se valide uniquement par l''Oracle.');
  END IF;
  IF v_q.created_at > now() - make_interval(mins => private.cfg_num('quest.min_age_minutes_declaratif')::int) THEN
    PERFORM private.fail('quete_trop_recente',
      format('Validation possible à partir de %s',
        v_q.created_at + make_interval(mins => private.cfg_num('quest.min_age_minutes_declaratif')::int)));
  END IF;

  RETURN private.complete_quest(v_user, p_quest_id, 'declaratif', NULL);
END;
$$;

-- ─── RPC : règles quotidiennes ───────────────────────────────────────────────

-- Idempotente : à appeler à chaque ouverture de l'app. Les pénalités de quêtes
-- manquées et la régénération sont recalculées à chaque appel ; la récompense
-- de connexion et la recharge d'énergie une fois par jour local.
CREATE OR REPLACE FUNCTION public.claim_daily()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user        uuid := private.require_user();
  v_stats       public.player_stats;
  v_today       date;
  v_last        date;
  v_q           record;
  v_missed      jsonb := '[]'::jsonb;
  v_hp_lost     numeric := 0;
  v_regen       integer;
  v_first_today boolean;
  v_login       jsonb := private.cfg('daily.login');
  v_energy      integer;
  v_floor       integer := private.cfg_num('oracle.daily_energy')::int;
  v_energy_gain numeric := 0;
  v_onboarding  numeric := 0;
  v_streak_lost boolean := false;
BEGIN
  v_stats := private.lock_player(v_user);
  v_today := private.local_today(v_user);

  -- 1. Quêtes manquées : échéance dépassée → échouée (jamais supprimée).
  FOR v_q IN
    SELECT id, title, difficulty FROM public.quests
    WHERE user_id = v_user AND status = 'active' AND deadline IS NOT NULL AND deadline < now()
    FOR UPDATE
  LOOP
    UPDATE public.quests SET status = 'failed', failed_at = now() WHERE id = v_q.id;
    v_hp_lost := v_hp_lost + private.ledger_apply(v_user, 'hp',
      -(private.cfg_num('hp.missed_per_difficulty') * greatest(1, least(4, v_q.difficulty))),
      'missed_quest', 'quest', v_q.id::text, 'missed:' || v_q.id::text || ':hp');
    PERFORM private.ledger_apply(v_user, 'moral', -private.cfg_num('moral.missed'),
      'missed_quest', 'quest', v_q.id::text, 'missed:' || v_q.id::text || ':moral');
    v_missed := v_missed || jsonb_build_array(jsonb_build_object('id', v_q.id, 'title', v_q.title));
  END LOOP;

  -- 2. Régénération des PV.
  v_regen := private.regen_hp(v_user);

  -- 3. Flamme éteinte après plus d'un jour sans quête validée.
  v_stats := private.lock_player(v_user);
  v_last := v_stats.last_streak_day;
  IF v_stats.streak > 0 AND (v_last IS NULL OR v_last < v_today - 1) THEN
    UPDATE public.player_stats SET streak = 0 WHERE user_id = v_user;
    v_streak_lost := true;
  END IF;

  -- 4. Une fois par jour : connexion et énergie de l'Oracle.
  -- Monotone : un jour déjà réclamé, ou antérieur, ne se réclame jamais.
  v_first_today := v_stats.last_daily_claim IS NULL OR v_stats.last_daily_claim < v_today;
  IF v_first_today THEN
    UPDATE public.player_stats SET last_daily_claim = v_today WHERE user_id = v_user;

    PERFORM private.ledger_apply(v_user, 'gold',  (v_login ->> 'gold')::int,  'daily_login', 'day', v_today::text, 'daily:' || v_today::text || ':gold');
    PERFORM private.ledger_apply(v_user, 'seals', (v_login ->> 'seals')::int, 'daily_login', 'day', v_today::text, 'daily:' || v_today::text || ':seals');

    INSERT INTO public.ai_validation_credits (user_id, balance) VALUES (v_user, 0)
    ON CONFLICT (user_id) DO NOTHING;

    IF NOT (SELECT onboarding_granted FROM public.ai_validation_credits WHERE user_id = v_user) THEN
      v_onboarding := private.ledger_apply(v_user, 'energy', private.cfg_num('oracle.onboarding_energy'),
        'oracle_onboarding', NULL, NULL, 'oracle:onboarding');
      UPDATE public.ai_validation_credits SET onboarding_granted = true WHERE user_id = v_user;
    END IF;

    SELECT balance INTO v_energy FROM public.ai_validation_credits WHERE user_id = v_user;
    IF v_energy < v_floor THEN
      v_energy_gain := private.ledger_apply(v_user, 'energy', v_floor - v_energy,
        'oracle_daily', 'day', v_today::text, 'oracle:daily:' || v_today::text);
    END IF;
    UPDATE public.ai_validation_credits SET last_daily_grant = now() WHERE user_id = v_user;
  END IF;

  RETURN jsonb_build_object(
    'first_today',      v_first_today,
    'login_reward',     CASE WHEN v_first_today THEN v_login ELSE NULL END,
    'energy_granted',   v_energy_gain + v_onboarding,
    'missed_quests',    v_missed,
    'hp_lost',          -v_hp_lost,
    'hp_regenerated',   v_regen,
    'streak_lost',      v_streak_lost
  );
END;
$$;

REVOKE ALL ON FUNCTION public.complete_quest(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.claim_daily()        FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_quest(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_daily()        TO authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC, anon, authenticated;

-- Les triggers de garde s'exécutent avec le rôle du client : ils ont besoin
-- de ces quelques fonctions en lecture seule. Le schéma `private` n'étant pas
-- exposé par l'API, elles restent inaccessibles depuis l'app.
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION
  private.is_client_role(),
  private.fail(text, text),
  private.cfg(text),
  private.cfg_num(text),
  private.expected_reward(integer, text),
  private.count_quest_creation(uuid)
TO authenticated;

COMMIT;
