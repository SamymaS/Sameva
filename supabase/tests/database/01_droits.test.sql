-- Sprint 1 : un client authentifié ne peut plus rien créditer par écriture directe.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(26);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT tests.create_user('bob@test.fr') AS bob \gset

-- État initial créé par le serveur.
SELECT tests.login(:'alice');
SELECT lives_ok($$ SELECT public.get_player_state() $$, 'get_player_state crée la ligne de stats');
SELECT tests.logout();

SELECT tests.login(:'alice');

-- player_stats
SELECT throws_ok($$ UPDATE public.player_stats SET gold = 999999 $$, '42501', NULL,
  'player_stats : modification directe de l''or refusée');
SELECT throws_ok($$ INSERT INTO public.player_stats (user_id, gold) VALUES (auth.uid(), 5000) $$, '42501', NULL,
  'player_stats : insertion directe refusée');
SELECT throws_ok($$ DELETE FROM public.player_stats $$, '42501', NULL,
  'player_stats : suppression refusée (reset de compte impossible)');
SELECT is((SELECT count(*)::int FROM public.player_stats), 1,
  'player_stats : on ne lit que sa propre ligne');

-- Énergie de l'Oracle
SELECT throws_ok($$ UPDATE public.ai_validation_credits SET balance = 999 $$, '42501', NULL,
  'ai_validation_credits : énergie non modifiable');
SELECT throws_ok($$ INSERT INTO public.ai_validation_credits (user_id, balance) VALUES (auth.uid(), 99) ON CONFLICT DO NOTHING $$, '42501', NULL,
  'ai_validation_credits : insertion refusée');

-- Registre
SELECT throws_ok($$ INSERT INTO public.economy_ledger (user_id, resource, amount, balance_after, reason) VALUES (auth.uid(), 'gold', 100, 100, 'triche') $$, '42501', NULL,
  'economy_ledger : insertion refusée');
SELECT throws_ok($$ UPDATE public.economy_ledger SET amount = 1 $$, '42501', NULL,
  'economy_ledger : modification refusée');

-- Gacha, preuves, abonnement
SELECT throws_ok($$ INSERT INTO public.gacha_state (user_id, banner, since_legendary) VALUES (auth.uid(), 'objets', 79) $$, '42501', NULL,
  'gacha_state : pity non falsifiable');
SELECT throws_ok($$ INSERT INTO public.quest_proofs (user_id, quest_id, image_sha256, status) VALUES (auth.uid(), gen_random_uuid(), repeat('a', 64), 'accepted') $$, '42501', NULL,
  'quest_proofs : verdict non falsifiable');
SELECT throws_ok($$ INSERT INTO public.premium_subscriptions (user_id, is_premium) VALUES (auth.uid(), true) $$, '42501', NULL,
  'premium_subscriptions : premium non auto-attribuable');
SELECT throws_ok($$ UPDATE public.game_config SET value = '[9999,9999,9999,9999]' WHERE key = 'quest.base_xp' $$, '42501', NULL,
  'game_config : réglages en lecture seule');
SELECT throws_ok($$ INSERT INTO public.transactions (user_id, type, gold_amount) VALUES (auth.uid(), 'reward', 1000) $$, '42501', NULL,
  'transactions : plus d''insertion client');

-- Fonctions réservées à l'Edge Function Oracle
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, gen_random_uuid(), repeat('a', 64)) $$, :'alice'), '42501', NULL,
  'oracle_begin : réservé au service_role');
SELECT throws_ok($$ SELECT public.oracle_resolve(gen_random_uuid(), 100, 'x', 'x') $$, '42501', NULL,
  'oracle_resolve : réservé au service_role');
SELECT throws_ok($$ SELECT public.oracle_abort(gen_random_uuid(), 'x') $$, '42501', NULL,
  'oracle_abort : réservé au service_role');

-- Fonctions internes inaccessibles
SELECT throws_ok(format($$ SELECT private.ledger_apply(%L, 'gold', 1000, 'triche') $$, :'alice'), '42501', NULL,
  'private.ledger_apply : inaccessible au client');
SELECT throws_ok(format($$ SELECT private.grant_xp(%L, 1000, 'triche') $$, :'alice'), '42501', NULL,
  'private.grant_xp : inaccessible au client');
SELECT throws_ok(format($$ SELECT private.complete_quest(%L, gen_random_uuid(), 'oracle') $$, :'alice'), '42501', NULL,
  'private.complete_quest : inaccessible au client');

-- Classement : colonnes publiques uniquement
SELECT is(
  (SELECT array_agg(column_name::text ORDER BY column_name::text) FROM information_schema.columns
   WHERE table_schema = 'public' AND table_name = 'leaderboard_view'),
  ARRAY['display_name', 'level', 'streak', 'user_id', 'xp'],
  'leaderboard_view : aucune colonne sensible');

SELECT tests.logout();

-- Isolation entre joueurs
SELECT tests.make_quest(:'bob') AS bob_quest \gset
SELECT tests.login(:'alice');
SELECT is((SELECT count(*)::int FROM public.quests WHERE id = :'bob_quest'), 0,
  'quests : la quête de Bob est invisible pour Alice');
SELECT throws_ok(format($$ SELECT public.complete_quest(%L) $$, :'bob_quest'), 'P0001', 'quete_introuvable',
  'complete_quest : impossible de valider la quête d''un autre');
SELECT tests.logout();

-- Visiteur non connecté
SELECT tests.as_anon();
SELECT throws_ok($$ SELECT public.get_player_state() $$, '42501', NULL, 'anon : aucune RPC de jeu');
SELECT throws_ok($$ SELECT * FROM public.player_stats $$, '42501', NULL, 'anon : aucune lecture des stats');
SELECT throws_ok($$ SELECT * FROM public.quests $$, '42501', NULL, 'anon : aucune lecture des quêtes');
SELECT tests.logout();

SELECT * FROM finish();
ROLLBACK;
