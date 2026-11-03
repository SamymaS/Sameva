-- Défi de capture : une photo antérieure au défi, ou préparée à l'avance, ne
-- peut pas valider une quête. Vérification « à l'aveugle » côté serveur.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(30);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT private.lock_player(:'alice');
SELECT private.ledger_apply(:'alice', 'energy', 10, 'test');
SELECT tests.make_quest(:'alice', 2, 'photo') AS q \gset

-- ─── Tirage du défi par l'app ───────────────────────────────────────────────
SELECT tests.login(:'alice');
SELECT public.oracle_challenge(:'q') AS c1 \gset
SELECT public.oracle_challenge(:'q') AS c1bis \gset
SELECT ok(:'c1'::jsonb ->> 'gesture' IS NOT NULL, 'défi standard : un geste');
SELECT ok((:'c1'::jsonb ->> 'number') ~ '^[1-9][0-9]$', 'défi standard : un nombre à 2 chiffres');
SELECT ok((:'c1'::jsonb ->> 'label') LIKE '%' || (:'c1'::jsonb ->> 'number') || '%', 'le libellé contient le nombre');
SELECT is(:'c1bis'::jsonb ->> 'challenge_id', :'c1'::jsonb ->> 'challenge_id', 'défi idempotent tant qu''il est valide');
SELECT ok((:'c1'::jsonb ->> 'expires_in')::int BETWEEN 170 AND 180, 'durée restante fournie en secondes (indépendante de l''horloge du téléphone)');
SELECT is((:'c1'::jsonb ->> 'rerolls_left')::int, 1, 'une relance disponible');

SELECT public.oracle_challenge(:'q', true) AS c2 \gset
SELECT isnt(:'c2'::jsonb ->> 'challenge_id', :'c1'::jsonb ->> 'challenge_id', 'relance : un nouveau défi');
SELECT isnt(:'c2'::jsonb ->> 'gesture', :'c1'::jsonb ->> 'gesture', 'relance : un autre geste');
SELECT throws_ok(format($$ SELECT public.oracle_challenge(%L, true) $$, :'q'), 'P0001', 'relance_epuisee',
  'une seule relance par quête');

-- Changer de mode ne remplace pas le défi en cours (pas de relance déguisée).
SELECT lives_ok($$ SELECT public.set_challenge_hands_free(true) $$, 'préférence « sans les mains » enregistrée');
SELECT is(public.oracle_challenge(:'q') ->> 'challenge_id', :'c2'::jsonb ->> 'challenge_id',
  'changer de mode ne retire pas le défi en cours');
SELECT throws_ok(format($$ SELECT public.oracle_challenge(%L, true) $$, :'q'), 'P0001', 'relance_epuisee',
  'changer de mode ne redonne pas de relance');
SELECT throws_ok($$ INSERT INTO public.oracle_challenges (user_id, quest_id, number_code, label, hands_free, expires_at)
  VALUES (auth.uid(), gen_random_uuid(), '12', 'x', true, now() + interval '1 day') $$, '42501', NULL,
  'un défi ne se fabrique pas côté client');
SELECT tests.logout();

-- Mode « sans les mains » : nombre à 3 chiffres, sans geste (nouvelle quête).
SELECT tests.make_quest(:'alice', 1, 'photo') AS q_hf \gset
SELECT tests.login(:'alice');
SELECT public.oracle_challenge(:'q_hf') AS chf \gset
SELECT tests.logout();
SELECT results_eq(
  format($$ SELECT %L::jsonb ->> 'gesture' IS NULL, (%L::jsonb ->> 'number') ~ '^[1-9][0-9]{2}$' $$, :'chf', :'chf'),
  $$ VALUES (true, true) $$,
  'sans les mains : pas de geste, un nombre à 3 chiffres');

-- Plafond quotidien par joueur.
UPDATE public.game_config SET value = jsonb_set(value, '{max_per_user_per_day}', '3') WHERE key = 'oracle.challenge';
SELECT tests.make_quest(:'alice', 1, 'photo') AS q_cap \gset
SELECT tests.login(:'alice');
SELECT throws_ok(format($$ SELECT public.oracle_challenge(%L) $$, :'q_cap'), 'P0001', 'plafond_atteint',
  'plafond de défis par joueur et par jour');
SELECT tests.logout();
UPDATE public.game_config SET value = jsonb_set(value, '{max_per_user_per_day}', '40') WHERE key = 'oracle.challenge';

-- ─── Ouverture de l'analyse ─────────────────────────────────────────────────
SELECT tests.as_service();
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L) $$, :'alice', :'q', repeat('a', 64)),
  'P0001', 'defi_requis', 'sans défi : analyse refusée');
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, %L) $$, :'alice', :'q', repeat('a', 64), :'c1'::jsonb ->> 'challenge_id'),
  'P0001', 'defi_invalide', 'défi remplacé par une relance : refusé');
SELECT tests.logout();

SELECT tests.challenge(:'alice', :'q') AS old_ch \gset
UPDATE public.oracle_challenges SET expires_at = now() - interval '2 minutes' WHERE id = :'old_ch';
SELECT tests.challenge(:'alice', :'q_hf') AS ch_autre \gset
SELECT tests.as_service();
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, %L) $$, :'alice', :'q', repeat('a', 64), :'old_ch'),
  'P0001', 'defi_expire', 'défi expiré : refusé');
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, %L) $$, :'alice', :'q', repeat('a', 64), :'ch_autre'),
  'P0001', 'defi_invalide', 'défi d''une autre quête : refusé');

-- Le défi attendu n'est jamais transmis à l'Oracle.
SELECT tests.logout();
SELECT tests.challenge(:'alice', :'q') AS ch1 \gset
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q', repeat('b', 64), :'ch1') AS b1 \gset
SELECT ok(NOT (:'b1'::jsonb ? 'challenge') AND (:'b1'::jsonb ->> 'challenge_required')::boolean,
  'oracle_begin ne révèle pas le défi attendu');
SELECT throws_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, %L) $$, :'alice', :'q', repeat('c', 64), :'ch1'),
  'P0001', 'defi_invalide', 'un défi ne sert qu''une fois');

-- ─── Verdict : comparaison à l'aveugle ──────────────────────────────────────
-- Ancienne photo parfaite (95) : l'Oracle voit un pouce mais aucun nombre.
SELECT public.oracle_resolve((:'b1'::jsonb ->> 'proof_id')::uuid, 95, 'Chambre impeccable', 'm', 'pouce', NULL) AS v1 \gset
SELECT tests.logout();
SELECT is((:'v1'::jsonb ->> 'accepted')::boolean, false, 'photo parfaite sans le nombre : refusée');

SELECT tests.challenge(:'alice', :'q') AS ch2 \gset
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q', repeat('d', 64), :'ch2') ->> 'proof_id' AS p2 \gset
-- Photo préparée à l'avance avec le bon geste mais un autre nombre.
SELECT is((public.oracle_resolve(:'p2', 92, 'ok', 'm', 'pouce', '17') ->> 'accepted')::boolean, false,
  'bon geste, mauvais nombre : refusée');
SELECT tests.logout();

SELECT tests.challenge(:'alice', :'q') AS ch3 \gset
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q', repeat('e', 64), :'ch3') ->> 'proof_id' AS p3 \gset
SELECT is((public.oracle_resolve(:'p3', 92, 'ok', 'm', 'v', '42') ->> 'accepted')::boolean, false,
  'bon nombre, mauvais geste : refusée');
SELECT tests.logout();

SELECT tests.challenge(:'alice', :'q') AS ch4 \gset
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q', repeat('f', 64), :'ch4') ->> 'proof_id' AS p4 \gset
-- L'Oracle lit « n°42 » : seuls les chiffres comptent.
SELECT public.oracle_resolve(:'p4', 90, 'Pouce et nombre bien visibles', 'm', ' Pouce ', 'n°42') AS v4 \gset
SELECT tests.logout();
SELECT is((:'v4'::jsonb ->> 'accepted')::boolean, true, 'geste et nombre conformes : acceptée');
SELECT is((SELECT status FROM public.quests WHERE id = :'q'), 'completed', 'la quête est close et récompensée');

-- Les refus « défi mal vu » ne pénalisent pas la crédibilité.
SELECT is((SELECT round(credibility_score::numeric, 2) FROM public.player_stats WHERE user_id = :'alice'), 0.90,
  'crédibilité : seules les preuves jugées sur le fond comptent');

-- ─── Panne de l'Oracle : énergie rendue et défi réutilisable ────────────────
SELECT tests.make_quest(:'alice', 1, 'photo') AS q5 \gset
SELECT tests.challenge(:'alice', :'q5') AS ch5 \gset
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'q5', repeat('1', 64), :'ch5') ->> 'proof_id' AS p5 \gset
SELECT is((public.oracle_abort(:'p5', 'Anthropic 529', true) ->> 'challenge_reusable')::boolean, true,
  'panne : le défi redevient utilisable');
SELECT lives_ok(format($$ SELECT public.oracle_begin(%L, %L, %L, %L) $$, :'alice', :'q5', repeat('2', 64), :'ch5'),
  'panne : la même photo peut être renvoyée avec le même défi');

-- Réponse inexploitable du modèle : pas de remboursement.
SELECT public.oracle_abort((SELECT id FROM public.quest_proofs WHERE image_sha256 = repeat('2', 64)), 'JSON illisible', false) AS a6 \gset
SELECT tests.logout();
SELECT is((:'a6'::jsonb ->> 'refunded')::int, 0, 'réponse inexploitable : énergie non rendue');

SELECT * FROM finish();
ROLLBACK;
