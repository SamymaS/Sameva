-- Sprint 2 : « ai » n'existe plus, tout passe par « photo ».
BEGIN;
\ir ../helpers/session.psql
SELECT plan(2);
SELECT tests.create_user('carla@test.fr') AS carla \gset
SELECT tests.login(:'carla');
SELECT throws_ok($$ INSERT INTO public.quests (user_id, title, difficulty, category, validation_type)
  VALUES (auth.uid(), 'x', 1, 'Maison', 'ai') $$, '23514', NULL, 'type « ai » refusé');
SELECT lives_ok($$ INSERT INTO public.quests (user_id, title, difficulty, category, validation_type)
  VALUES (auth.uid(), 'y', 1, 'Maison', 'photo') $$, 'type « photo » accepté');
SELECT tests.logout();
SELECT * FROM finish();
ROLLBACK;
