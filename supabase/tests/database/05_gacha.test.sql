-- Sprint 1 : gacha serveur, payé en Sceaux, pity persistée.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(15);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT private.lock_player(:'alice');

SELECT tests.login(:'alice');
SELECT throws_ok($$ SELECT public.invoke('objets', 1) $$, 'P0001', 'solde_insuffisant', 'sans Sceaux : invocation refusée');
SELECT throws_ok($$ SELECT public.invoke('inconnue', 1) $$, 'P0001', 'banniere_inconnue', 'bannière inconnue refusée');
SELECT throws_ok($$ SELECT public.invoke('objets', 5) $$, 'P0001', 'nombre_invalide', 'seuls 1 ou 10 tirages');

-- Tirage gratuit quotidien
SELECT public.invoke('objets', 1, true) AS f1 \gset
SELECT is(jsonb_array_length(:'f1'::jsonb -> 'results'), 1, 'tirage gratuit : 1 résultat');
SELECT is((:'f1'::jsonb ->> 'seals_spent')::int, 0, 'tirage gratuit : 0 Sceau');
SELECT throws_ok($$ SELECT public.invoke('objets', 1, true) $$, 'P0001', 'gratuit_deja_utilise', 'un seul tirage gratuit par jour');
SELECT throws_ok($$ SELECT public.invoke('compagnons', 1, true) $$, 'P0001', 'gratuit_indisponible', 'pas de gratuit sur les compagnons');
SELECT tests.logout();

-- Coûts
SELECT private.ledger_apply(:'alice', 'seals', 200, 'test');
SELECT tests.login(:'alice');
SELECT public.invoke('objets', 1) AS s1 \gset
SELECT public.invoke('objets', 10) AS s10 \gset
SELECT tests.logout();
SELECT is((:'s1'::jsonb ->> 'seals_spent')::int, 10, 'tirage simple : 10 Sceaux');
SELECT is((:'s10'::jsonb ->> 'seals_spent')::int, 90, 'tirage ×10 : 90 Sceaux');
SELECT is((SELECT seals FROM public.player_stats WHERE user_id = :'alice'), 100, 'solde : 200 - 10 - 90 = 100');
SELECT is((SELECT count(*)::int FROM public.gacha_pulls WHERE user_id = :'alice'), 12, 'historique : 12 tirages');

-- Pity dure, avec des taux forcés à 100 % commun pour rendre le test déterministe.
UPDATE public.game_config SET value = '{"common": 100, "uncommon": 0, "rare": 0, "epic": 0, "legendary": 0, "mythic": 0}'
WHERE key = 'gacha.rates';
UPDATE public.game_config SET value = '{"epic_every": 20, "legendary_at": 80, "soft_start": 1000, "soft_step_percent": 0}'
WHERE key = 'gacha.pity';
UPDATE public.gacha_state SET since_epic = 18, since_legendary = 18 WHERE user_id = :'alice' AND banner = 'objets';
SELECT tests.login(:'alice');
SELECT public.invoke('objets', 1) AS p19 \gset
SELECT public.invoke('objets', 1) AS p20 \gset
SELECT tests.logout();
SELECT is(:'p19'::jsonb -> 'results' -> 0 ->> 'rarity', 'common', '19e tirage : commun');
SELECT results_eq(
  format($$ SELECT %L::jsonb -> 'results' -> 0 ->> 'rarity', (%L::jsonb -> 'results' -> 0 ->> 'by_pity')::boolean $$, :'p20', :'p20'),
  $$ VALUES ('epic'::text, true) $$,
  '20e tirage : épique garanti');

UPDATE public.gacha_state SET since_legendary = 79 WHERE user_id = :'alice' AND banner = 'objets';
SELECT tests.login(:'alice');
SELECT public.invoke('objets', 1) AS p80 \gset
SELECT tests.logout();
SELECT is(:'p80'::jsonb -> 'results' -> 0 ->> 'rarity', 'legendary', '80e tirage : légendaire garanti');
SELECT results_eq(
  $$ SELECT since_epic, since_legendary FROM public.gacha_state WHERE user_id = $$ || quote_literal(:'alice') || $$::uuid AND banner = 'objets' $$,
  $$ VALUES (0, 0) $$,
  'compteurs remis à zéro après un légendaire');

SELECT * FROM finish();
ROLLBACK;
