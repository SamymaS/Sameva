-- Sprint 1 : non-régression des failles trouvées par la revue de sécurité.
BEGIN;
\ir ../helpers/session.psql
SELECT plan(20);

SELECT tests.create_user('alice@test.fr') AS alice \gset
SELECT private.lock_player(:'alice');

-- ─── Fuseau horaire : changement limité à une fois tous les 30 jours ────────
SELECT tests.login(:'alice');
SELECT lives_ok($$ SELECT public.set_timezone('Pacific/Kiritimati') $$, 'premier changement de fuseau accepté');
SELECT throws_ok($$ SELECT public.set_timezone('Etc/GMT+12') $$, 'P0001', 'fuseau_verrouille',
  'second changement dans les 30 jours refusé');
SELECT lives_ok($$ SELECT public.set_timezone('Pacific/Kiritimati') $$, 'redéclarer le même fuseau est sans effet');
SELECT throws_ok($$ SELECT public.set_timezone('Mars/Olympus') $$, 'P0001', 'fuseau_invalide', 'fuseau inconnu refusé');
SELECT tests.logout();

-- ─── Marqueurs quotidiens monotones ─────────────────────────────────────────
-- Un jour « futur » déjà consommé (fuseau avancé puis reculé) bloque les jours antérieurs.
UPDATE public.player_stats SET last_daily_claim = private.local_today(user_id) + 1 WHERE user_id = :'alice';
INSERT INTO public.gacha_state (user_id, banner, last_free_pull_on) VALUES (:'alice', 'objets', private.local_today(:'alice') + 1);
SELECT tests.login(:'alice');
SELECT is((public.claim_daily() ->> 'first_today')::boolean, false, 'claim_daily : pas de réclamation rétroactive');
SELECT throws_ok($$ SELECT public.invoke('objets', 1, true) $$, 'P0001', 'gratuit_deja_utilise',
  'tirage gratuit : pas de retour sur un jour antérieur');
SELECT tests.logout();

-- La flamme ne progresse pas deux fois le même jour de référence.
UPDATE public.player_stats SET streak = 6, last_streak_day = private.local_today(user_id),
  last_active_date = now() - interval '2 hours' WHERE user_id = :'alice';
SELECT is((private.complete_quest(:'alice', tests.make_quest(:'alice', 1), 'declaratif') ->> 'streak')::int, 6,
  'flamme : même jour de référence, pas de +1');

-- ─── Quêtes : ce qui fixe la récompense se fige ─────────────────────────────
SELECT tests.make_quest(:'alice', 2, 'photo', interval '1 hour', now() + interval '2 days') AS qp \gset
SELECT tests.login(:'alice');
SELECT throws_ok(format($$ UPDATE public.quests SET validation_type = 'manual' WHERE id = %L $$, :'qp'),
  'P0001', 'champ_verrouille', 'quête photo : impossible de la rendre déclarative');
SELECT throws_ok(format($$ UPDATE public.quests SET difficulty = 4 WHERE id = %L $$, :'qp'),
  'P0001', 'champ_verrouille', 'difficulté figée après la fenêtre d''édition');
SELECT throws_ok(format($$ UPDATE public.quests SET title = 'photo de mon bureau' WHERE id = %L $$, :'qp'),
  'P0001', 'champ_verrouille', 'titre figé après la fenêtre d''édition');
SELECT throws_ok(format($$ UPDATE public.quests SET deadline = deadline + interval '5 days' WHERE id = %L $$, :'qp'),
  'P0001', 'champ_verrouille', 'échéance : impossible de la repousser');
SELECT lives_ok(format($$ UPDATE public.quests SET deadline = deadline - interval '1 day' WHERE id = %L $$, :'qp'),
  'échéance : avancer reste possible');
SELECT tests.logout();

-- Une quête fraîche reste modifiable, sauf dès qu'une preuve est soumise.
SELECT tests.make_quest(:'alice', 1, 'photo', interval '1 minute') AS qf \gset
SELECT private.ledger_apply(:'alice', 'energy', 2, 'test');
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'qf', repeat('1', 64), tests.challenge(:'alice', :'qf'));
SELECT tests.logout();
SELECT tests.login(:'alice');
SELECT throws_ok(format($$ UPDATE public.quests SET difficulty = 4 WHERE id = %L $$, :'qf'),
  'P0001', 'champ_verrouille', 'preuve soumise : difficulté figée même dans la fenêtre d''édition');

-- Quête échue : suppression impossible (la pénalité ne s'esquive pas).
SELECT tests.logout();
SELECT tests.make_quest(:'alice', 3, 'manual', interval '2 days', now() - interval '1 hour') AS qe \gset
SELECT tests.login(:'alice');
SELECT throws_ok(format($$ DELETE FROM public.quests WHERE id = %L $$, :'qe'),
  'P0001', 'quete_echue', 'quête échue : suppression refusée');

-- Plafond de création insensible aux suppressions.
SELECT tests.logout();
UPDATE public.game_config SET value = '3' WHERE key = 'quest.max_created_per_day';
SELECT tests.login(:'alice');
INSERT INTO public.quests (user_id, title, difficulty, category) VALUES (auth.uid(), 'a', 1, 'Maison'), (auth.uid(), 'b', 1, 'Maison');
DELETE FROM public.quests WHERE title IN ('a', 'b');
INSERT INTO public.quests (user_id, title, difficulty, category) VALUES (auth.uid(), 'c', 1, 'Maison');
SELECT throws_ok($$ INSERT INTO public.quests (user_id, title, difficulty, category) VALUES (auth.uid(), 'd', 1, 'Maison') $$,
  'P0001', 'plafond_atteint', 'créer puis supprimer ne contourne pas le plafond');

-- ─── Bonus d'échéance : il faut un vrai engagement ──────────────────────────
SELECT tests.logout();
SELECT tests.make_quest(:'alice', 2, 'manual', interval '1 hour', now() + interval '1 hour') AS qd \gset
SELECT is((private.complete_quest(:'alice', :'qd', 'declaratif') -> 'factors' ->> 'planning')::numeric, 1.0,
  'échéance fixée 2 h après la création : pas de bonus');
SELECT tests.login(:'alice');

-- ─── Doublons : pas de tirage, pas de remboursement ─────────────────────────
SELECT is((public.claim_transitional_reward('doublon', 30) ->> 'granted')::int, 0,
  'doublon sans tirage du jour : rien');
SELECT tests.logout();

-- ─── Énergie plafonnée ──────────────────────────────────────────────────────
SELECT private.ledger_apply(:'alice', 'energy', 50, 'test');
SELECT is((SELECT balance FROM public.ai_validation_credits WHERE user_id = :'alice'), 10,
  'énergie : plafond de stockage de 10');

-- ─── Analyse abandonnée : nettoyée et remboursée au prochain envoi ──────────
UPDATE public.quest_proofs SET created_at = now() - interval '10 minutes' WHERE quest_id = :'qf';
SELECT tests.as_service();
SELECT public.oracle_begin(:'alice', :'qf', repeat('2', 64), tests.challenge(:'alice', :'qf'));
SELECT tests.logout();
SELECT is((SELECT status FROM public.quest_proofs WHERE quest_id = :'qf' AND image_sha256 = repeat('1', 64)), 'error',
  'analyse abandonnée : close automatiquement');
SELECT is((SELECT count(*)::int FROM public.economy_ledger WHERE user_id = :'alice' AND reason = 'oracle_refund'), 1,
  'analyse abandonnée : énergie rendue');

SELECT * FROM finish();
ROLLBACK;
