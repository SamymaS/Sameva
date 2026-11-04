-- =============================================================================
-- Sprint 1 · 3/4 : Oracle autoritaire et défi de capture
-- =============================================================================
-- Le verdict de l'Oracle n'est plus une simple information renvoyée au client :
-- il est enregistré, consomme de l'énergie et, au-dessus du seuil, termine la
-- quête et distribue les récompenses dans la même transaction.
--
-- oracle_begin / oracle_resolve / oracle_abort sont réservées au rôle
-- `service_role`, c'est-à-dire à l'Edge Function `analyze-quest-proof`.
--
-- Défi de capture (ADR 0006) : l'Oracle juge le contenu d'une photo, pas sa
-- date ; une ancienne photo de chambre rangée serait acceptée, et le client ne
-- peut pas prouver qu'une photo vient d'être prise. Au moment de la capture,
-- le serveur tire donc un geste ET un nombre à écrire sur un papier (630
-- combinaisons ; 900 nombres à 3 chiffres en mode « sans les mains »). Une
-- photo antérieure au défi ne peut pas les contenir, et une bibliothèque de
-- photos préparées à l'avance ne suffit plus.
--
-- Vérification « à l'aveugle » : l'Oracle ne connaît PAS le défi demandé. Il
-- décrit ce qu'il voit (geste parmi une liste fermée, chiffres manuscrits) et
-- c'est le serveur qui compare. Le modèle ne peut donc pas être poussé à
-- répondre « oui, le défi est visible », ni par complaisance, ni par une
-- injection dans le titre de la quête.
-- =============================================================================

BEGIN;

-- ─── Réglages ────────────────────────────────────────────────────────────────

INSERT INTO public.game_config (key, value, description) VALUES
  ('oracle.challenge', '{"enabled": true, "ttl_seconds": 180, "upload_grace_seconds": 60, "rerolls_per_quest": 1, "max_per_quest_per_day": 10, "max_per_user_per_day": 40, "code_digits": 2, "code_digits_hands_free": 3}',
   'Défi de capture : validité, délai d''envoi, relances, plafonds, longueur du nombre à écrire'),
  ('oracle.challenge_gestures', '[
     {"code": "pouce", "label": "un pouce levé"},
     {"code": "v",     "label": "deux doigts en V"},
     {"code": "trois", "label": "trois doigts levés"},
     {"code": "paume", "label": "la main ouverte, doigts écartés"},
     {"code": "poing", "label": "le poing fermé"},
     {"code": "ok",    "label": "le signe OK (pouce et index en cercle)"},
     {"code": "index", "label": "l''index tendu"}
   ]', 'Gestes possibles. Les codes sont ceux que MougiBot sait reconnaître (liste fermée du prompt)'),
  ('oracle.max_error_proofs_per_day', '10',
   'Analyses en erreur tolérées par jour et par joueur (au-delà : plafond, protège la facture IA)'),
  ('oracle.dhash_max_distance', '4',
   'Distance de Hamming sous laquelle une photo est signalée comme proche d''une preuve déjà acceptée (audit, non bloquant)'),
  ('oracle.dhash_lookback_days', '30', 'Profondeur de la comparaison d''empreintes perceptuelles')
ON CONFLICT (key) DO NOTHING;

-- Préférence d'accessibilité, stockée côté serveur (et non passée à chaque
-- appel, sinon basculer de mode servirait à retirer un défi sans limite).
ALTER TABLE public.player_stats
  ADD COLUMN IF NOT EXISTS challenge_hands_free boolean NOT NULL DEFAULT false;

-- ─── Défis de capture ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.oracle_challenges (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_id      uuid        NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  gesture_code  text,
  gesture_label text,
  number_code   text        NOT NULL CHECK (number_code ~ '^[0-9]{2,4}$'),
  label         text        NOT NULL,
  hands_free    boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  expires_at    timestamptz NOT NULL,
  used_at       timestamptz,
  replaced      boolean     NOT NULL DEFAULT false,
  CHECK (hands_free OR gesture_code IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS oracle_challenges_quest_idx ON public.oracle_challenges (quest_id, created_at DESC);
CREATE INDEX IF NOT EXISTS oracle_challenges_user_idx  ON public.oracle_challenges (user_id, created_at DESC);

ALTER TABLE public.oracle_challenges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "oracle_challenges_select_own" ON public.oracle_challenges;
CREATE POLICY "oracle_challenges_select_own" ON public.oracle_challenges
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.oracle_challenges FROM anon, authenticated;
GRANT SELECT ON public.oracle_challenges TO authenticated;

-- ─── Preuves ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.quest_proofs (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_id         uuid        NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  status           text        NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'accepted', 'rejected', 'error')),
  score            integer     CHECK (score BETWEEN 0 AND 100),
  explanation      text,
  model            text,
  image_sha256     text        NOT NULL CHECK (image_sha256 ~ '^[0-9a-f]{64}$'),
  image_dhash      bigint,
  near_duplicate_of uuid,
  energy_consumed  boolean     NOT NULL DEFAULT false,
  error            text,
  challenge_id     uuid REFERENCES public.oracle_challenges(id) ON DELETE SET NULL,
  challenge_ok     boolean,
  observed_gesture text,
  observed_code    text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  resolved_at      timestamptz
);

COMMENT ON TABLE public.quest_proofs IS
  'Une ligne par analyse Oracle. L''image n''est pas conservée : seules son '
  'empreinte exacte (SHA-256, bloquante) et son empreinte perceptuelle (dHash, '
  'signal d''audit) le sont, avec ce que l''Oracle a observé du défi.';

CREATE INDEX IF NOT EXISTS quest_proofs_user_time_idx ON public.quest_proofs (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS quest_proofs_quest_idx     ON public.quest_proofs (quest_id);
CREATE UNIQUE INDEX IF NOT EXISTS quest_proofs_unique_accepted_image
  ON public.quest_proofs (user_id, image_sha256) WHERE status = 'accepted';

ALTER TABLE public.quest_proofs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "quest_proofs_select_own" ON public.quest_proofs;
CREATE POLICY "quest_proofs_select_own" ON public.quest_proofs
  FOR SELECT TO authenticated USING ((SELECT auth.uid()) = user_id);
REVOKE ALL ON public.quest_proofs FROM anon, authenticated;
GRANT SELECT ON public.quest_proofs TO authenticated;

-- ─── RPC : préférence « défis sans les mains » ───────────────────────────────

CREATE OR REPLACE FUNCTION public.set_challenge_hands_free(p_hands_free boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user uuid := private.require_user();
BEGIN
  PERFORM private.lock_player(v_user);
  UPDATE public.player_stats SET challenge_hands_free = coalesce(p_hands_free, false)
  WHERE user_id = v_user;
END;
$$;

-- Ce que voit l'app. `expires_in` (secondes) évite de dépendre de l'horloge
-- du téléphone, qui peut être décalée.
CREATE OR REPLACE FUNCTION private.challenge_payload(p_ch public.oracle_challenges)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT jsonb_build_object(
    'challenge_id',  p_ch.id,
    'label',         p_ch.label,
    'gesture',       p_ch.gesture_label,
    'number',        p_ch.number_code,
    'hands_free',    p_ch.hands_free,
    'expires_at',    p_ch.expires_at,
    'expires_in',    greatest(0, floor(extract(epoch FROM p_ch.expires_at - now())))::int,
    'rerolls_left',  greatest(0, (private.cfg('oracle.challenge') ->> 'rerolls_per_quest')::int
                     - (SELECT count(*) FROM public.oracle_challenges WHERE quest_id = p_ch.quest_id AND replaced)::int)
  )
$$;

-- ─── RPC : tirage du défi ────────────────────────────────────────────────────

-- Appelée par l'app avant d'ouvrir la caméra. Renvoie le défi en cours s'il
-- est encore valide (idempotent), sinon en tire un nouveau. `p_reroll`
-- remplace un défi encore valide : une fois par quête, quel que soit le mode.
-- La préférence « sans les mains » s'applique aux prochains tirages.
CREATE OR REPLACE FUNCTION public.oracle_challenge(
  p_quest_id uuid,
  p_reroll   boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user       uuid := private.require_user();
  v_cfg        jsonb := private.cfg('oracle.challenge');
  v_stats      public.player_stats;
  v_q          public.quests;
  v_current    public.oracle_challenges;
  v_has        boolean;
  v_gesture    jsonb;
  v_digits     integer;
  v_number     text;
  v_label      text;
  v_row        public.oracle_challenges;
BEGIN
  v_stats := private.lock_player(v_user);
  SELECT * INTO v_q FROM public.quests WHERE id = p_quest_id AND user_id = v_user FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.fail('quete_introuvable');
  END IF;
  IF v_q.status <> 'active' THEN
    PERFORM private.fail('quete_deja_cloturee');
  END IF;

  -- Ménage paresseux : les défis jamais utilisés de plus de 7 jours.
  DELETE FROM public.oracle_challenges
  WHERE user_id = v_user AND used_at IS NULL AND created_at < now() - interval '7 days';

  SELECT * INTO v_current FROM public.oracle_challenges
  WHERE quest_id = p_quest_id AND used_at IS NULL AND NOT replaced AND expires_at > now()
  ORDER BY created_at DESC LIMIT 1;
  v_has := FOUND;

  IF v_has AND NOT p_reroll THEN
    RETURN private.challenge_payload(v_current);
  END IF;

  IF v_has AND p_reroll AND (
       SELECT count(*) FROM public.oracle_challenges WHERE quest_id = p_quest_id AND replaced
     ) >= (v_cfg ->> 'rerolls_per_quest')::int THEN
    PERFORM private.fail('relance_epuisee', 'Le défi de cette quête a déjà été changé.');
  END IF;

  IF (SELECT count(*) FROM public.oracle_challenges
      WHERE quest_id = p_quest_id AND created_at > now() - interval '24 hours')
     >= (v_cfg ->> 'max_per_quest_per_day')::int
  OR (SELECT count(*) FROM public.oracle_challenges
      WHERE user_id = v_user AND created_at > now() - interval '24 hours')
     >= (v_cfg ->> 'max_per_user_per_day')::int THEN
    PERFORM private.fail('plafond_atteint', 'Trop de défis demandés aujourd''hui.');
  END IF;

  IF v_has THEN
    UPDATE public.oracle_challenges SET replaced = true WHERE id = v_current.id;
  END IF;

  -- Nombre à écrire : uniforme, sans zéro de tête (plus lisible à l'écrit).
  v_digits := (v_cfg ->> CASE WHEN v_stats.challenge_hands_free THEN 'code_digits_hands_free' ELSE 'code_digits' END)::int;
  v_number := (power(10, v_digits - 1)::int + floor(random() * 9 * power(10, v_digits - 1))::int)::text;

  IF v_stats.challenge_hands_free THEN
    v_label := format('le nombre %s écrit sur un papier posé bien en vue', v_number);
  ELSE
    -- Geste : de préférence un geste pas encore tiré pour cette quête.
    SELECT e INTO v_gesture
    FROM jsonb_array_elements(private.cfg('oracle.challenge_gestures')) AS e
    ORDER BY (e ->> 'code') IN (
               SELECT gesture_code FROM public.oracle_challenges
               WHERE quest_id = p_quest_id AND gesture_code IS NOT NULL),
             random()
    LIMIT 1;
    v_label := format('%s, et le nombre %s écrit sur un papier', v_gesture ->> 'label', v_number);
  END IF;

  INSERT INTO public.oracle_challenges
    (user_id, quest_id, gesture_code, gesture_label, number_code, label, hands_free, expires_at)
  VALUES
    (v_user, p_quest_id, v_gesture ->> 'code', v_gesture ->> 'label', v_number, v_label,
     v_stats.challenge_hands_free, now() + make_interval(secs => (v_cfg ->> 'ttl_seconds')::int))
  RETURNING * INTO v_row;

  RETURN private.challenge_payload(v_row);
END;
$$;

-- ─── Échec : l'énergie est rendue si l'Oracle n'a pas pu juger ───────────────
-- (déclarée avant oracle_begin et oracle_resolve, qui l'appellent)

-- p_refund = false quand le modèle a bien répondu mais de façon inexploitable
-- (texte dans l'image qui le fait divaguer) : un tel échec ne doit pas offrir
-- des appels IA gratuits à l'infini.
CREATE OR REPLACE FUNCTION public.oracle_abort(p_proof_id uuid, p_error text, p_refund boolean DEFAULT true)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_proof    public.quest_proofs;
  v_refunded numeric := 0;
  v_reusable boolean := false;
BEGIN
  SELECT * INTO v_proof FROM public.quest_proofs WHERE id = p_proof_id FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.fail('preuve_introuvable');
  END IF;
  IF v_proof.status <> 'pending' THEN
    RETURN jsonb_build_object('proof_id', p_proof_id, 'refunded', 0, 'challenge_reusable', false);
  END IF;

  UPDATE public.quest_proofs SET status = 'error', error = left(p_error, 500), resolved_at = now()
  WHERE id = p_proof_id;

  IF p_refund AND v_proof.energy_consumed THEN
    v_refunded := private.ledger_apply(v_proof.user_id, 'energy', 1, 'oracle_refund', 'proof',
      p_proof_id::text, 'proof:' || p_proof_id::text || ':refund');
  END IF;

  -- Panne de notre côté : le défi redevient utilisable s'il est encore dans
  -- son délai, pour que le joueur renvoie la même photo sans la reprendre.
  IF p_refund AND v_proof.challenge_id IS NOT NULL THEN
    UPDATE public.oracle_challenges SET used_at = NULL
    WHERE id = v_proof.challenge_id
      AND expires_at + make_interval(secs => (private.cfg('oracle.challenge') ->> 'upload_grace_seconds')::int) > now()
    RETURNING true INTO v_reusable;
  END IF;

  RETURN jsonb_build_object('proof_id', p_proof_id, 'refunded', v_refunded,
    'challenge_reusable', coalesce(v_reusable, false));
END;
$$;

-- ─── Ouverture d'une analyse ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.oracle_begin(
  p_user         uuid,
  p_quest_id     uuid,
  p_image_sha256 text,
  p_challenge_id uuid   DEFAULT NULL,
  p_image_dhash  bigint DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_q        public.quests;
  v_premium  boolean;
  v_today    integer;
  v_energy   integer;
  v_proof_id uuid;
  v_consumed boolean := false;
  v_stale    record;
  v_ch_cfg   jsonb := private.cfg('oracle.challenge');
  v_ch       public.oracle_challenges;
  v_near     uuid;
BEGIN
  -- Ordre de verrouillage commun : joueur, puis quête. Le verrou joueur
  -- sérialise aussi les contrôles de plafonds.
  PERFORM private.lock_player(p_user);

  -- Nettoyage paresseux : une analyse restée en cours au-delà du délai
  -- (Edge Function interrompue) est close et son énergie rendue.
  FOR v_stale IN
    SELECT id FROM public.quest_proofs
    WHERE user_id = p_user AND status = 'pending'
      AND created_at <= now() - make_interval(secs => private.cfg_num('oracle.pending_timeout_seconds')::int)
  LOOP
    PERFORM public.oracle_abort(v_stale.id, 'Délai dépassé (nettoyage automatique)', true);
  END LOOP;

  SELECT * INTO v_q FROM public.quests
  WHERE id = p_quest_id AND user_id = p_user
  FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.fail('quete_introuvable');
  END IF;
  IF v_q.status <> 'active' THEN
    PERFORM private.fail('quete_deja_cloturee');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.quest_proofs
    WHERE user_id = p_user AND image_sha256 = lower(p_image_sha256) AND status = 'accepted'
  ) THEN
    PERFORM private.fail('photo_deja_utilisee', 'Cette photo a déjà validé une quête.');
  END IF;

  -- Les échecs d'analyse coûtent un appel IA : on les plafonne.
  IF (SELECT count(*) FROM public.quest_proofs
      WHERE user_id = p_user AND status = 'error' AND created_at >= private.local_day_start(p_user))
     >= private.cfg_num('oracle.max_error_proofs_per_day') THEN
    PERFORM private.fail('plafond_atteint', 'Trop d''analyses en échec aujourd''hui.');
  END IF;

  -- Défi de capture : obligatoire, à usage unique, dans son délai.
  IF coalesce((v_ch_cfg ->> 'enabled')::boolean, false) THEN
    IF p_challenge_id IS NULL THEN
      PERFORM private.fail('defi_requis');
    END IF;
    SELECT * INTO v_ch FROM public.oracle_challenges
    WHERE id = p_challenge_id AND user_id = p_user AND quest_id = p_quest_id
    FOR UPDATE;
    IF NOT FOUND OR v_ch.used_at IS NOT NULL OR v_ch.replaced THEN
      PERFORM private.fail('defi_invalide');
    END IF;
    IF now() > v_ch.expires_at + make_interval(secs => (v_ch_cfg ->> 'upload_grace_seconds')::int) THEN
      PERFORM private.fail('defi_expire', 'Le défi a expiré : reprends une photo avec un nouveau défi.');
    END IF;
    UPDATE public.oracle_challenges SET used_at = now() WHERE id = v_ch.id;
  END IF;

  -- Une seule analyse en cours par quête (évite les doubles envois).
  IF EXISTS (
    SELECT 1 FROM public.quest_proofs
    WHERE quest_id = p_quest_id AND status = 'pending'
      AND created_at > now() - make_interval(secs => private.cfg_num('oracle.pending_timeout_seconds')::int)
  ) THEN
    PERFORM private.fail('analyse_en_cours');
  END IF;

  v_premium := private.is_premium(p_user);
  IF v_premium THEN
    -- Toutes les analyses comptent, y compris celles en erreur.
    SELECT count(*) INTO v_today FROM public.quest_proofs
    WHERE user_id = p_user AND created_at >= private.local_day_start(p_user);
    IF v_today >= private.cfg_num('oracle.premium_daily_cap') THEN
      PERFORM private.fail('plafond_atteint', 'Limite quotidienne d''analyses atteinte.');
    END IF;
  ELSE
    INSERT INTO public.ai_validation_credits (user_id, balance) VALUES (p_user, 0)
    ON CONFLICT (user_id) DO NOTHING;
    SELECT balance INTO v_energy FROM public.ai_validation_credits WHERE user_id = p_user FOR UPDATE;
    IF v_energy < 1 THEN
      PERFORM private.fail('energie_insuffisante');
    END IF;
    v_consumed := true;
  END IF;

  -- Empreinte perceptuelle : signal d'audit, jamais bloquant (le défi de
  -- capture garantit déjà la fraîcheur ; une même pièce photographiée chaque
  -- jour sous le même angle ne doit pas être refusée).
  IF p_image_dhash IS NOT NULL THEN
    SELECT id INTO v_near FROM public.quest_proofs
    WHERE user_id = p_user AND status = 'accepted' AND image_dhash IS NOT NULL
      AND created_at > now() - make_interval(days => private.cfg_num('oracle.dhash_lookback_days')::int)
      AND bit_count((image_dhash # p_image_dhash)::bit(64)) <= private.cfg_num('oracle.dhash_max_distance')
    ORDER BY created_at DESC LIMIT 1;
  END IF;

  INSERT INTO public.quest_proofs
    (user_id, quest_id, image_sha256, image_dhash, near_duplicate_of, energy_consumed, challenge_id)
  VALUES
    (p_user, p_quest_id, lower(p_image_sha256), p_image_dhash, v_near, v_consumed, v_ch.id)
  RETURNING id INTO v_proof_id;

  IF v_consumed THEN
    PERFORM private.ledger_apply(p_user, 'energy', -1, 'oracle_analysis', 'proof', v_proof_id::text,
      'proof:' || v_proof_id::text || ':energy');
  END IF;

  -- Le défi attendu n'est PAS renvoyé : l'Oracle doit décrire sans savoir.
  RETURN jsonb_build_object(
    'proof_id',           v_proof_id,
    'title',              v_q.title,
    'category',           v_q.category,
    'premium',            v_premium,
    'threshold',          private.cfg_num('oracle.threshold')::int,
    'challenge_required', v_ch.id IS NOT NULL
  );
END;
$$;

-- ─── Verdict ─────────────────────────────────────────────────────────────────

-- p_observed_gesture / p_observed_code : ce que l'Oracle a VU (sans connaître
-- le défi). La comparaison avec le défi attendu se fait ici, côté serveur.
CREATE OR REPLACE FUNCTION public.oracle_resolve(
  p_proof_id         uuid,
  p_score            integer,
  p_explanation      text,
  p_model            text,
  p_observed_gesture text DEFAULT NULL,
  p_observed_code    text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_proof        public.quest_proofs;
  v_ch           public.oracle_challenges;
  v_threshold    integer := private.cfg_num('oracle.threshold')::int;
  v_code         text := nullif(regexp_replace(coalesce(p_observed_code, ''), '[^0-9]', '', 'g'), '');
  v_challenge_ok boolean := NULL;
  v_accepted     boolean;
  v_rewards      jsonb := NULL;
  v_status       text;
BEGIN
  SELECT * INTO v_proof FROM public.quest_proofs WHERE id = p_proof_id FOR UPDATE;
  IF NOT FOUND THEN
    PERFORM private.fail('preuve_introuvable');
  END IF;
  IF v_proof.status <> 'pending' THEN
    PERFORM private.fail('preuve_deja_traitee');
  END IF;
  IF p_score IS NULL OR p_score < 0 OR p_score > 100 THEN
    PERFORM private.fail('score_invalide');
  END IF;

  -- La quête a été terminée ou supprimée pendant l'analyse : rien n'est jugé,
  -- l'énergie est rendue.
  IF NOT EXISTS (SELECT 1 FROM public.quests WHERE id = v_proof.quest_id AND status = 'active') THEN
    RETURN public.oracle_abort(p_proof_id, 'Quête close pendant l''analyse', true)
      || jsonb_build_object('accepted', false, 'quest_closed', true, 'rewards', NULL);
  END IF;

  IF v_proof.challenge_id IS NOT NULL THEN
    SELECT * INTO v_ch FROM public.oracle_challenges WHERE id = v_proof.challenge_id;
    v_challenge_ok := (v_ch.gesture_code IS NULL OR v_ch.gesture_code = lower(trim(coalesce(p_observed_gesture, ''))))
                      AND v_code IS NOT DISTINCT FROM v_ch.number_code;
  END IF;

  v_accepted := p_score >= v_threshold AND (v_proof.challenge_id IS NULL OR v_challenge_ok IS TRUE);
  v_status := CASE WHEN v_accepted THEN 'accepted' ELSE 'rejected' END;

  UPDATE public.quest_proofs SET
    status           = v_status,
    score            = p_score,
    explanation      = left(p_explanation, 500),
    model            = p_model,
    challenge_ok     = v_challenge_ok,
    observed_gesture = left(p_observed_gesture, 20),
    observed_code    = left(v_code, 8),
    resolved_at      = now()
  WHERE id = p_proof_id;

  IF v_accepted THEN
    v_rewards := private.complete_quest(v_proof.user_id, v_proof.quest_id, 'oracle', p_proof_id);
  END IF;

  -- Score de crédibilité = moyenne des scores Oracle, ramenée entre 0 et 1.
  -- Les preuves refusées uniquement pour un défi mal vu n'y entrent pas.
  UPDATE public.player_stats SET credibility_score = (
    SELECT coalesce(avg(score), 100) / 100.0 FROM public.quest_proofs
    WHERE user_id = v_proof.user_id AND status IN ('accepted', 'rejected')
      AND NOT (status = 'rejected' AND challenge_ok IS FALSE AND score >= v_threshold)
  )
  WHERE user_id = v_proof.user_id;

  RETURN jsonb_build_object(
    'proof_id',     p_proof_id,
    'quest_id',     v_proof.quest_id,
    'accepted',     v_accepted,
    'score',        p_score,
    'threshold',    v_threshold,
    'explanation',  p_explanation,
    'challenge',    v_ch.label,
    'challenge_ok', v_challenge_ok,
    'rewards',      v_rewards
  );
END;
$$;

REVOKE ALL ON FUNCTION public.oracle_begin(uuid, uuid, text, uuid, bigint)            FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.oracle_resolve(uuid, integer, text, text, text, text)   FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.oracle_abort(uuid, text, boolean)                       FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.oracle_challenge(uuid, boolean)                         FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_challenge_hands_free(boolean)                       FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION private.challenge_payload(public.oracle_challenges)            FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.oracle_begin(uuid, uuid, text, uuid, bigint)          TO service_role;
GRANT EXECUTE ON FUNCTION public.oracle_resolve(uuid, integer, text, text, text, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.oracle_abort(uuid, text, boolean)                     TO service_role;
GRANT EXECUTE ON FUNCTION public.oracle_challenge(uuid, boolean)                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_challenge_hands_free(boolean)                     TO authenticated;

COMMIT;
