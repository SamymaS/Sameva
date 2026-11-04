-- Sprint 2 : MougiBot « suggester » (Edge Function suggest-quests) n'est plus
-- appelable par n'importe qui avec la clé anon publique.
--
-- Avant : verify_jwt acceptait la clé anon (un JWT de rôle anon), donc chaque
-- appel coûtait un appel Claude sans utilisateur identifié ni plafond.
-- Après : la fonction exige une session utilisateur et consomme d'abord un
-- quota quotidien côté serveur. Le profil envoyé à l'IA (niveau, flamme,
-- quêtes accomplies) est lu en base, plus jamais fourni par le client.

INSERT INTO public.game_config (key, value, description) VALUES
  ('mougibot.suggestions_per_day',       '5', 'Générations de quêtes par MougiBot par jour (compte)'),
  ('mougibot.suggestions_per_day_guest', '1', 'Générations de quêtes par MougiBot par jour (invité)')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.player_stats
  ADD COLUMN IF NOT EXISTS suggestions_on    date,
  ADD COLUMN IF NOT EXISTS suggestions_count integer NOT NULL DEFAULT 0;

-- Réserve une génération pour l'utilisateur courant et renvoie son profil.
-- Appelée par l'Edge Function avec le JWT de l'utilisateur, avant l'appel IA.
CREATE OR REPLACE FUNCTION public.mougibot_suggest_take()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid   uuid := private.require_user();
  v_row   public.player_stats;
  v_today date;
  v_guest boolean := coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false);
  v_cap   integer;
  v_used  integer;
BEGIN
  v_row := private.lock_player(v_uid);
  v_today := private.local_today(v_uid);
  v_cap := private.cfg_num(CASE WHEN v_guest THEN 'mougibot.suggestions_per_day_guest'
                                ELSE 'mougibot.suggestions_per_day' END)::int;
  v_used := CASE WHEN v_row.suggestions_on = v_today THEN v_row.suggestions_count ELSE 0 END;

  IF v_used >= v_cap THEN
    PERFORM private.fail('plafond_atteint', format('%s générations par jour', v_cap));
  END IF;

  UPDATE public.player_stats
     SET suggestions_on = v_today, suggestions_count = v_used + 1
   WHERE user_id = v_uid;

  RETURN jsonb_build_object(
    'player_level',           v_row.level,
    'current_streak',         v_row.streak,
    'total_quests_completed', v_row.total_quests_completed,
    'remaining',              v_cap - v_used - 1
  );
END;
$$;

-- Rend la génération si l'IA a échoué. Réservé au serveur (service_role) :
-- un client qui pourrait se rembourser lui-même contournerait le plafond.
CREATE OR REPLACE FUNCTION public.mougibot_suggest_refund(p_user uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.player_stats
     SET suggestions_count = greatest(suggestions_count - 1, 0)
   WHERE user_id = p_user
     AND suggestions_on = private.local_today(p_user);
END;
$$;

REVOKE ALL ON FUNCTION public.mougibot_suggest_take()        FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mougibot_suggest_refund(uuid)  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mougibot_suggest_take()       TO authenticated;
GRANT EXECUTE ON FUNCTION public.mougibot_suggest_refund(uuid) TO service_role;
