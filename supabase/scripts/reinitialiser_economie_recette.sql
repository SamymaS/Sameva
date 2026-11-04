-- =============================================================================
-- Remise à zéro de l'économie des comptes de RECETTE (à lancer une seule fois,
-- juste après le déploiement du Sprint 1, dans l'éditeur SQL du dashboard).
-- =============================================================================
-- Pourquoi : avant le Sprint 1, l'app pouvait écrire n'importe quel solde. Les
-- valeurs des comptes de test ne sont donc pas fiables. La migration les a
-- ramenées dans des bornes valides et inscrites comme « soldes d'ouverture »,
-- mais ne peut pas savoir lesquelles ont été gonflées.
--
-- Ce script garde les comptes, les quêtes et l'historique des preuves, et remet
-- à zéro la progression et les ressources de TOUS les joueurs. Il ne fait rien
-- si un joueur a déjà gagné quelque chose depuis le Sprint 1 (sécurité contre
-- une exécution tardive en production avec de vrais utilisateurs).
-- =============================================================================

BEGIN;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.economy_ledger WHERE reason <> 'opening_balance') THEN
    RAISE EXCEPTION 'Des mouvements post-Sprint 1 existent : remise à zéro refusée.';
  END IF;
END $$;

DELETE FROM public.economy_ledger WHERE reason = 'opening_balance';

UPDATE public.player_stats SET
  level = 1, experience = 0, total_experience = 0,
  gold = 0, crystals = 0, seals = 0, stardust = 0,
  health_points = 100, max_health_points = 100, moral = 1.0,
  streak = 0, max_streak = 0, last_streak_day = NULL, last_active_date = NULL,
  total_quests_completed = 0, credibility_score = 1.0, is_exhausted = false,
  last_daily_claim = NULL;

UPDATE public.ai_validation_credits SET balance = 0, onboarding_granted = false;
DELETE FROM public.gacha_state;

COMMIT;

-- Vérification : doit renvoyer 0 ligne.
SELECT user_id FROM public.player_stats WHERE gold <> 0 OR level <> 1;
