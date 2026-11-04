-- Sprint 1 : passerelles transitoires plafonnées et cohérence du registre.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(14);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT private.lock_player(:'alice');
SELECT private.ledger_apply(:'alice', 'gold', 500, 'test');

SELECT tests.login(:'alice');

-- Débit seul
SELECT throws_ok($$ SELECT public.spend('gold', -100, 'marche_achat') $$, 'P0001', 'montant_invalide',
  'spend : un montant négatif (donc un crédit) est refusé');
SELECT throws_ok($$ SELECT public.spend('seals', 1, 'marche_achat') $$, 'P0001', 'ressource_invalide',
  'spend : les Sceaux ne se dépensent qu''au gacha');
SELECT throws_ok($$ SELECT public.spend('gold', 10, 'cadeau') $$, 'P0001', 'motif_invalide',
  'spend : motif inconnu refusé');
SELECT throws_ok($$ SELECT public.spend('gold', 501, 'marche_achat') $$, 'P0001', 'solde_insuffisant',
  'spend : pas de découvert');
SELECT lives_ok($$ SELECT public.spend('gold', 120, 'marche_achat', 'epee_bois') $$, 'spend : achat valide');

-- Gains plafonnés
SELECT public.claim_transitional_reward('vente_objet', 200) AS g1 \gset
SELECT public.claim_transitional_reward('vente_objet', 200) AS g2 \gset
SELECT public.claim_transitional_reward('vente_objet', 10) AS g3 \gset
SELECT is((:'g1'::jsonb ->> 'granted')::int, 200, 'vente : 200 accordés');
SELECT is((:'g2'::jsonb ->> 'granted')::int, 100, 'vente : plafond de 300 par jour atteint');
SELECT is((:'g3'::jsonb ->> 'capped')::boolean, true, 'vente : au-delà du plafond, plus rien');
SELECT throws_ok($$ SELECT public.claim_transitional_reward('triche', 10) $$, 'P0001', 'source_invalide',
  'source inconnue refusée');
SELECT is((public.claim_transitional_reward('potion_xp', 1000) ->> 'granted')::int, 100,
  'potion d''XP : plafonnée à 100 par jour');
SELECT tests.logout();

SELECT is((SELECT gold FROM public.player_stats WHERE user_id = :'alice'), 680,
  'or final : 500 - 120 + 300');

-- ─── Conservation : chaque solde égale la somme de ses mouvements ───────────
SELECT private.complete_quest(:'alice', tests.make_quest(:'alice', 4, 'photo'), 'oracle');
SELECT results_eq(
  $$ SELECT ps.gold::numeric, ps.crystals::numeric, ps.seals::numeric, ps.total_experience::numeric
     FROM public.player_stats ps WHERE ps.user_id = $$ || quote_literal(:'alice') || $$::uuid $$,
  $$ SELECT
       coalesce(sum(amount) FILTER (WHERE resource = 'gold'), 0),
       coalesce(sum(amount) FILTER (WHERE resource = 'crystals'), 0),
       coalesce(sum(amount) FILTER (WHERE resource = 'seals'), 0),
       coalesce(sum(amount) FILTER (WHERE resource = 'xp'), 0)
     FROM public.economy_ledger WHERE user_id = $$ || quote_literal(:'alice') || $$::uuid $$,
  'registre : soldes = somme des mouvements');

-- Le registre est immuable, même pour le service_role.
SELECT tests.as_service();
SELECT throws_ok($$ UPDATE public.economy_ledger SET amount = 999999 $$, '42501', NULL,
  'registre : le service_role ne peut pas le réécrire');
SELECT tests.logout();
SELECT throws_ok($$ UPDATE public.economy_ledger SET amount = 999999 $$, 'P0001', 'registre_immuable',
  'registre : même l''administrateur est bloqué par le trigger');

SELECT * FROM finish();
ROLLBACK;
