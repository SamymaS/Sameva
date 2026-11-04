-- Sprint 1 : l'Oracle décide, consomme de l'énergie et récompense côté serveur.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(22);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT tests.login(:'alice');
SELECT public.claim_daily();          -- onboarding : 5 énergie
SELECT tests.logout();
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 5,
  'onboarding : 5 énergie');

SELECT tests.make_quest(:'alice', 2, 'photo') AS q1 \gset
SELECT tests.make_quest(:'alice', 4, 'photo') AS q2 \gset

-- ─── Preuve rejetée : l'énergie est consommée, rien n'est gagné ─────────────
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q1', repeat('a', 64), tests.challenge(:'alice', :'q1')) ->> 'proof_id' AS p1 \gset
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, tests.challenge(%L, %L)) $$, :'alice', :'q1', repeat('b', 64), :'alice', :'q1'),
  'P0001', 'analyse_en_cours', 'une seule analyse à la fois par quête');
SELECT public.oracle_resolve(:'p1', 55, 'Photo trop floue', 'claude-haiku-4-5', 'pouce', '42') AS v1 \gset
SELECT tests.logout();

SELECT is((:'v1'::jsonb ->> 'accepted')::boolean, false, 'score 55 : refusé');
SELECT is(:'v1'::jsonb -> 'rewards', 'null'::jsonb, 'score 55 : aucune récompense');
SELECT is((SELECT status FROM public.quests WHERE id = :'q1'), 'active', 'score 55 : la quête reste active');
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 4,
  'score 55 : 1 énergie consommée');

-- ─── Preuve acceptée : quête close et récompensée dans la même transaction ──
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q1', repeat('c', 64), tests.challenge(:'alice', :'q1')) ->> 'proof_id' AS p2 \gset
SELECT public.oracle_resolve(:'p2', 86, 'Bravo, chambre rangée', 'claude-haiku-4-5', 'pouce', '42') AS v2 \gset
SELECT tests.logout();

SELECT is((:'v2'::jsonb ->> 'accepted')::boolean, true, 'score 86 : accepté');
SELECT is((:'v2'::jsonb -> 'rewards' ->> 'xp')::int, 30, 'Oracle diff 2 : 30 XP pleins');
SELECT is((:'v2'::jsonb -> 'rewards' ->> 'seals')::int, 1, 'Oracle diff 2 : 1 Sceau');
SELECT results_eq(
  $$ SELECT status::text, validated_by FROM public.quests WHERE id = $$ || quote_literal(:'q1') || $$::uuid $$,
  $$ VALUES ('completed'::text, 'oracle'::text) $$,
  'score 86 : quête close par l''Oracle');
SELECT is((SELECT round(credibility_score::numeric, 3) FROM public.player_stats WHERE user_id = :'alice'), 0.705,
  'crédibilité = moyenne des scores (55 et 86)');

-- ─── Photo réutilisée ───────────────────────────────────────────────────────
SELECT tests.as_service();
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, tests.challenge(%L, %L)) $$, :'alice', :'q2', repeat('c', 64), :'alice', :'q2'),
  'P0001', 'photo_deja_utilisee', 'une photo ayant validé une quête est refusée ensuite');

-- ─── Échec technique : énergie rendue ───────────────────────────────────────
SELECT public.oracle_begin(:'alice', :'q2', repeat('d', 64), tests.challenge(:'alice', :'q2')) ->> 'proof_id' AS p3 \gset
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 2,
  'énergie : 5 - 3 analyses = 2');
SELECT is((public.oracle_abort(:'p3', 'Timeout Anthropic') ->> 'refunded')::int, 1, 'échec technique : énergie rendue');
SELECT is((SELECT status FROM public.quest_proofs WHERE id = :'p3'), 'error', 'échec technique : preuve en erreur');
SELECT throws_ok(format($$ SELECT public.oracle_resolve(%L, 99, 'x', 'x', 'pouce', '42') $$, :'p3'),
  'P0001', 'preuve_deja_traitee', 'une preuve close ne peut plus être jugée');
SELECT tests.logout();
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 3,
  'énergie après remboursement : 3');

-- ─── Énergie épuisée ────────────────────────────────────────────────────────
SELECT private.ledger_apply(:'alice', 'energy', -3, 'test');
SELECT tests.as_service();
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, tests.challenge(%L, %L)) $$, :'alice', :'q2', repeat('e', 64), :'alice', :'q2'),
  'P0001', 'energie_insuffisante', 'sans énergie : analyse refusée');
SELECT tests.logout();

-- ─── Abonné : pas de consommation, plafond quotidien ────────────────────────
INSERT INTO public.premium_subscriptions (user_id, is_premium) VALUES (:'alice', true);
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q2', repeat('f', 64), tests.challenge(:'alice', :'q2')) ->> 'proof_id' AS p4 \gset
SELECT tests.logout();
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 0,
  'abonné : aucune énergie consommée');
SELECT is((SELECT energy_consumed FROM public.quest_proofs WHERE id = :'p4'), false,
  'abonné : preuve marquée sans consommation');

UPDATE public.game_config SET value = '3' WHERE key = 'oracle.premium_daily_cap';
SELECT tests.as_service();
SELECT tests.make_quest(:'alice', 1, 'photo') AS q9 \gset
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, tests.challenge(%L, %L)) $$, :'alice', :'q9', repeat('9', 64), :'alice', :'q9'),
  'P0001', 'plafond_atteint', 'abonné : plafond quotidien appliqué');

-- ─── Verdict de l'analyse de l'abonné ──────────────────────────────────────
SELECT public.oracle_resolve(:'p4', 95, 'Parfait', 'claude-haiku-4-5', 'pouce', '42') AS v4 \gset
SELECT tests.logout();
SELECT is((:'v4'::jsonb -> 'rewards' ->> 'seals')::int, 2, 'abonné, diff 4 accepté : 2 Sceaux');

SELECT * FROM finish();
ROLLBACK;
