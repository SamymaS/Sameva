-- Sprint 1 : règles quotidiennes calculées par le serveur, de façon idempotente.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(17);

SELECT tests.create_user('alice@test.fr') AS alice \gset

-- ─── Première ouverture du jour ─────────────────────────────────────────────
SELECT tests.login(:'alice');
SELECT public.claim_daily() AS d1 \gset
SELECT public.claim_daily() AS d2 \gset
SELECT tests.logout();

SELECT is((:'d1'::jsonb ->> 'first_today')::boolean, true,  'premier appel du jour');
SELECT is((:'d2'::jsonb ->> 'first_today')::boolean, false, 'second appel : déjà réclamé');
SELECT results_eq(
  $$ SELECT gold, seals FROM public.player_stats WHERE user_id = $$ || quote_literal(:'alice') || $$::uuid $$,
  $$ VALUES (30, 1) $$,
  'connexion : 30 or et 1 Sceau, une seule fois');
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 5,
  'énergie : onboarding 5 (le plancher de 3 ne s''ajoute pas)');

-- Le lendemain, l'énergie remonte au plancher de 3 si elle est en dessous.
SELECT private.ledger_apply(:'alice', 'energy', -4, 'test');
UPDATE public.player_stats SET last_daily_claim = last_daily_claim - 1 WHERE user_id = :'alice';
SELECT tests.login(:'alice');
SELECT public.claim_daily() AS d3 \gset
SELECT tests.logout();
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 3,
  'lendemain : énergie rechargée au plancher de 3');
SELECT is((:'d3'::jsonb ->> 'energy_granted')::int, 2, 'lendemain : +2 énergie');

-- ─── Quêtes manquées : échouées, jamais supprimées ──────────────────────────
SELECT tests.make_quest(:'alice', 3, 'manual', interval '2 days', now() - interval '1 hour') AS missed \gset
SELECT tests.make_quest(:'alice', 1, 'manual', interval '2 days', now() + interval '1 day') AS future \gset
SELECT tests.login(:'alice');
SELECT public.claim_daily() AS d4 \gset
SELECT public.claim_daily() AS d5 \gset
SELECT tests.logout();

SELECT is((SELECT status FROM public.quests WHERE id = :'missed'), 'failed', 'échéance dépassée : quête échouée');
SELECT is((SELECT status FROM public.quests WHERE id = :'future'), 'active', 'échéance future : quête intacte');
SELECT is((:'d4'::jsonb ->> 'hp_lost')::int, 30, 'quête manquée diff 3 : -30 PV');
SELECT is(jsonb_array_length(:'d5'::jsonb -> 'missed_quests'), 0, 'pénalité appliquée une seule fois');
SELECT results_eq(
  $$ SELECT health_points, round(moral::numeric, 2) FROM public.player_stats WHERE user_id = $$ || quote_literal(:'alice') || $$::uuid $$,
  $$ VALUES (70, 0.90) $$,
  'PV et moral après la quête manquée');

-- ─── État Épuisé : récompenses à 50 % jusqu'à la prochaine quête prouvée ────
SELECT private.ledger_apply(:'alice', 'hp', -1000, 'test');
SELECT is((SELECT is_exhausted FROM public.player_stats WHERE user_id = :'alice'), true, 'PV à 0 : Épuisé');
SELECT private.complete_quest(:'alice', tests.make_quest(:'alice', 2), 'declaratif') AS r1 \gset
SELECT is((:'r1'::jsonb ->> 'xp')::int, 8, 'Épuisé + déclaratif : 30 × 0,5 × 0,5 = 7,5 → 8 XP');
SELECT is((SELECT is_exhausted FROM public.player_stats WHERE user_id = :'alice'), true,
  'une quête déclarative ne lève pas l''état Épuisé');
SELECT private.complete_quest(:'alice', tests.make_quest(:'alice', 2, 'photo'), 'oracle');
SELECT is((SELECT is_exhausted FROM public.player_stats WHERE user_id = :'alice'), false,
  'une quête prouvée lève l''état Épuisé');
SELECT is((SELECT level FROM public.player_stats WHERE user_id = :'alice'), 1,
  'PV à 0 : aucun retour en arrière de niveau');

-- ─── Régénération ───────────────────────────────────────────────────────────
UPDATE public.player_stats SET health_points = 50, last_hp_regen_at = now() - interval '3 hours 20 minutes'
WHERE user_id = :'alice';
SELECT is(private.regen_hp(:'alice'), 15, '3 heures pleines : +15 PV (5 % de 100 par heure)');

SELECT * FROM finish();
ROLLBACK;
