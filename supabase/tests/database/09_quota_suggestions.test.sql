-- Sprint 2 : MougiBot « suggester » exige une session et respecte un quota.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(10);

SELECT tests.create_user('bob@test.fr') AS bob \gset
SELECT private.lock_player(:'bob');
UPDATE public.player_stats SET level = 7, streak = 3 WHERE user_id = :'bob';

-- Sans session : refusé (la clé anon ne suffit plus).
SELECT tests.as_anon();
SELECT throws_ok($$ SELECT public.mougibot_suggest_take() $$, '42501', NULL,
  'visiteur anonyme (clé anon seule) : refusé');
SELECT tests.logout();

-- Compte : 5 générations par jour, profil lu en base.
SELECT tests.login(:'bob');
SELECT is((public.mougibot_suggest_take() ->> 'player_level')::int, 7, 'profil lu en base (niveau)');
SELECT is((public.mougibot_suggest_take() ->> 'current_streak')::int, 3, 'profil lu en base (flamme)');
SELECT public.mougibot_suggest_take();
SELECT public.mougibot_suggest_take();
SELECT is((public.mougibot_suggest_take() ->> 'remaining')::int, 0, 'cinquième génération : plus rien en réserve');
SELECT throws_ok($$ SELECT public.mougibot_suggest_take() $$, 'P0001', 'plafond_atteint',
  'sixième génération du jour refusée');

-- Un client ne peut pas se rembourser lui-même.
SELECT throws_ok(format($$ SELECT public.mougibot_suggest_refund(%L) $$, :'bob'), '42501', NULL,
  'remboursement interdit au client');
SELECT tests.logout();

-- Le serveur rend une génération après un échec de l'IA.
SELECT tests.as_service();
SELECT lives_ok(format($$ SELECT public.mougibot_suggest_refund(%L) $$, :'bob'), 'remboursement par le serveur');
SELECT tests.logout();
SELECT tests.login(:'bob');
SELECT lives_ok($$ SELECT public.mougibot_suggest_take() $$, 'génération rendue : de nouveau possible');
SELECT tests.logout();

-- Invité : une seule génération par jour.
SELECT tests.create_user('invite@test.fr') AS inv \gset
SELECT set_config('request.jwt.claims',
  json_build_object('sub', :'inv', 'role', 'authenticated', 'is_anonymous', true)::text, true);
SET LOCAL ROLE authenticated;
SELECT lives_ok($$ SELECT public.mougibot_suggest_take() $$, 'invité : première génération');
SELECT throws_ok($$ SELECT public.mougibot_suggest_take() $$, 'P0001', 'plafond_atteint',
  'invité : une seule génération par jour');
SELECT tests.logout();

SELECT * FROM finish();
ROLLBACK;
