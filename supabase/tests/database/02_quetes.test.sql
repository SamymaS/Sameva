-- Sprint 1 : cycle de vie des quêtes et calcul serveur des récompenses.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(34);

SELECT tests.create_user('alice@test.fr') AS alice \gset

-- ─── Insertion par le client : l'économie est imposée ───────────────────────
SELECT tests.login(:'alice');
INSERT INTO public.quests (user_id, title, difficulty, category, validation_type, status, is_completed,
                           xp_reward, gold_reward, created_at, completed_at)
VALUES (auth.uid(), 'Triche', 3, 'Maison', 'manual', 'completed', true, 99999, 99999,
        now() - interval '3 days', now());
SELECT tests.logout();

SELECT results_eq(
  $$ SELECT status::text, is_completed, xp_reward, gold_reward, completed_at IS NULL, created_at = now()
     FROM public.quests WHERE title = 'Triche' $$,
  $$ VALUES ('active'::text, false, 50, 70, true, true) $$,
  'insertion : statut, récompenses et date de création imposés par le serveur');

SELECT tests.login(:'alice');
SELECT throws_ok($$ INSERT INTO public.quests (user_id, title, difficulty, category) VALUES (auth.uid(), 'Boss maison', 4, 'boss') $$,
  'P0001', 'categorie_reservee', 'insertion : un boss ne peut pas être créé par le client');
SELECT throws_ok($$ INSERT INTO public.quests (user_id, title, difficulty, category) VALUES (auth.uid(), 'Hors borne', 5, 'Maison') $$,
  '23514', NULL, 'insertion : difficulté 5 refusée');

-- ─── Modification par le client ─────────────────────────────────────────────
SELECT throws_ok($$ UPDATE public.quests SET status = 'completed' WHERE title = 'Triche' $$,
  'P0001', 'champ_protege', 'modification : le statut est protégé');
SELECT throws_ok($$ UPDATE public.quests SET is_completed = true WHERE title = 'Triche' $$,
  'P0001', 'champ_protege', 'modification : is_completed est protégé');
SELECT lives_ok($$ UPDATE public.quests SET title = 'Ranger le salon', xp_reward = 5000 WHERE title = 'Triche' $$,
  'modification : le titre reste éditable');
SELECT is((SELECT xp_reward FROM public.quests WHERE title = 'Ranger le salon'), 50,
  'modification : xp_reward est recalculé, jamais pris du client');
SELECT lives_ok($$ UPDATE public.quests SET difficulty = 1 WHERE title = 'Ranger le salon' $$,
  'modification : la difficulté d''une quête active reste éditable');
SELECT is((SELECT gold_reward FROM public.quests WHERE title = 'Ranger le salon'), 20,
  'modification : récompense attendue recalculée avec la nouvelle difficulté');

-- ─── Validation déclarative ─────────────────────────────────────────────────
SELECT throws_ok($$ SELECT public.complete_quest((SELECT id FROM public.quests WHERE title = 'Ranger le salon')) $$,
  'P0001', 'quete_trop_recente', 'déclaratif : refusé avant 10 minutes');
SELECT tests.logout();

-- Quête de difficulté 2, créée il y a 1 h, sans échéance : V = 0,5, P = 1, S = 1, K = 1.
SELECT tests.make_quest(:'alice', 2, 'manual', interval '1 hour') AS q1 \gset
SELECT tests.login(:'alice');
SELECT public.complete_quest(:'q1') AS r1 \gset
SELECT tests.logout();

SELECT is((:'r1'::jsonb ->> 'xp')::int,   15, 'déclaratif diff 2 : 30 XP × 0,5 = 15');
SELECT is((:'r1'::jsonb ->> 'gold')::int, 20, 'déclaratif diff 2 : 40 or × 0,5 = 20');
SELECT is((:'r1'::jsonb ->> 'seals')::int, 0, 'déclaratif : aucun Sceau');
SELECT is((:'r1'::jsonb ->> 'streak')::int, 1, 'première quête : flamme à 1');
SELECT results_eq(
  $$ SELECT status::text, is_completed, validated_by, rewarded_at IS NOT NULL FROM public.quests WHERE id = $$ || quote_literal(:'q1') || $$::uuid $$,
  $$ VALUES ('completed'::text, true, 'declaratif'::text, true) $$,
  'déclaratif : la quête est close et marquée');
SELECT results_eq(
  $$ SELECT gold, total_experience::int, streak, total_quests_completed FROM public.player_stats WHERE user_id = $$ || quote_literal(:'alice') || $$::uuid $$,
  $$ VALUES (20, 15, 1, 1) $$,
  'déclaratif : soldes mis à jour côté serveur');

SELECT tests.login(:'alice');
SELECT throws_ok(format($$ SELECT public.complete_quest(%L) $$, :'q1'),
  'P0001', 'quete_deja_cloturee', 'double validation impossible');
SELECT lives_ok(format($$ DELETE FROM public.quests WHERE id = %L $$, :'q1'),
  'suppression d''une quête terminée : sans erreur mais sans effet');
SELECT tests.logout();
SELECT is((SELECT count(*)::int FROM public.quests WHERE id = :'q1'), 1,
  'une quête terminée reste dans l''historique');

-- Quête photo : la voie déclarative est fermée.
SELECT tests.make_quest(:'alice', 2, 'photo') AS qp \gset
SELECT tests.login(:'alice');
SELECT throws_ok(format($$ SELECT public.complete_quest(%L) $$, :'qp'),
  'P0001', 'preuve_requise', 'quête photo : validation déclarative refusée');
SELECT tests.logout();

-- ─── Bonus de planification et d'échéance ───────────────────────────────────
-- Diff 4, créée il y a 9 h, échéance tenue : P = 1 + 0,10 + 0,10 = 1,2.
SELECT tests.make_quest(:'alice', 4, 'manual', interval '9 hours', now() + interval '1 hour') AS q2 \gset
SELECT tests.login(:'alice');
SELECT public.complete_quest(:'q2') AS r2 \gset
SELECT tests.logout();
SELECT is((:'r2'::jsonb -> 'factors' ->> 'planning')::numeric, 1.20, 'planification + échéance : P = 1,2');
SELECT is((:'r2'::jsonb ->> 'xp')::int, 48, 'diff 4 déclaratif planifié : 80 × 0,5 × 1,2 = 48 XP');
SELECT is((:'r2'::jsonb ->> 'gold')::int, 66, 'diff 4 déclaratif planifié : 110 × 0,5 × 1,2 = 66 or');

-- ─── Rendements décroissants ────────────────────────────────────────────────
-- Alice a déjà 2 quêtes récompensées aujourd'hui ; on en valide 3 de plus (rang 3 à 5),
-- puis la 6e doit passer à 50 %, et la 11e à XP seule.
DO $$
DECLARE v_user uuid := (SELECT id FROM auth.users WHERE email = 'alice@test.fr'); i int;
BEGIN
  FOR i IN 1..3 LOOP
    PERFORM private.complete_quest(v_user, tests.make_quest(v_user, 1), 'declaratif');
  END LOOP;
END $$;
SELECT private.complete_quest(:'alice', tests.make_quest(:'alice', 2), 'declaratif') AS r6 \gset
SELECT is((:'r6'::jsonb -> 'factors' ->> 'daily_rank')::int, 6, 'rang 6 dans la journée');
SELECT is((:'r6'::jsonb ->> 'xp')::int, 8, 'rang 6 : 30 × 0,5 × 0,5 = 7,5 arrondi à 8');
DO $$
DECLARE v_user uuid := (SELECT id FROM auth.users WHERE email = 'alice@test.fr'); i int;
BEGIN
  FOR i IN 1..4 LOOP
    PERFORM private.complete_quest(v_user, tests.make_quest(v_user, 1), 'declaratif');
  END LOOP;
END $$;
SELECT private.complete_quest(:'alice', tests.make_quest(:'alice', 4), 'oracle') AS r11 \gset
SELECT is((:'r11'::jsonb -> 'factors' ->> 'daily_rank')::int, 11, 'rang 11 dans la journée');
SELECT is((:'r11'::jsonb ->> 'gold')::int, 0, 'au-delà de 10 : plus d''or');
SELECT is((:'r11'::jsonb ->> 'seals')::int, 0, 'au-delà de 10 : plus de Sceaux');
SELECT is((:'r11'::jsonb ->> 'xp')::int, 8, 'au-delà de 10 : XP à 10 % (80 × 0,1)');

-- ─── Flamme et montée de niveau ─────────────────────────────────────────────
SELECT tests.create_user('carla@test.fr') AS carla \gset
SELECT private.lock_player(:'carla');
-- Carla a validé une quête hier avec une flamme de 6 jours : la quête d'aujourd'hui atteint 7.
UPDATE public.player_stats SET streak = 6, last_active_date = now() - interval '1 day',
  last_streak_day = private.local_today(user_id) - 1, experience = 140
WHERE user_id = :'carla';
SELECT private.complete_quest(:'carla', tests.make_quest(:'carla', 4), 'oracle') AS r7 \gset
SELECT is((:'r7'::jsonb ->> 'streak')::int, 7, 'flamme : 6 → 7');
SELECT is((:'r7'::jsonb -> 'factors' ->> 'streak')::numeric, 1.10, 'flamme de 7 jours : bonus de 10 %');
SELECT is(jsonb_array_length(:'r7'::jsonb -> 'streak_milestones'), 1, 'palier de 7 jours atteint');
SELECT is((:'r7'::jsonb ->> 'level_after')::int, 2, 'montée au niveau 2 (140 + 88 ≥ 150)');
SELECT results_eq(
  $$ SELECT level, experience, max_health_points, crystals, seals FROM public.player_stats WHERE user_id = $$ || quote_literal(:'carla') || $$::uuid $$,
  -- 80 × 1,1 = 88 XP ; cristaux : 1 (quête) + 4 (niveau 2) + 5 (palier) ; Sceaux : 2
  $$ VALUES (2, 78, 110, 10, 2) $$,
  'niveau, PV max, cristaux et Sceaux cohérents après montée de niveau');

SELECT * FROM finish();
ROLLBACK;
