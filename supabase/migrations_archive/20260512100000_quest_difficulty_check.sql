-- ============================================================
-- Migration : correction des quêtes historiques difficulty=5
-- + table d'audit + contrainte CHECK
-- ============================================================
-- Contexte : un bug du DifficultyPicker (DropdownButton) permettait
-- de sélectionner difficulty=5, hors plage [1-4].
-- 3 quêtes complétées ont été enregistrées avec cette valeur.
-- Les récompenses ont été créditées sur la base de difficulty=5 :
--   XP = 50, Gold = 125 par quête (QuestRewardsCalculator)
-- La valeur correcte est difficulty=4 :
--   XP = 40, Gold = 100 par quête
-- Surplus par quête : -10 XP, -25 Gold
-- Surplus total (3 quêtes) : -30 XP, -75 Gold
--
-- Opérations réalisées par cette migration :
--   1. Création table d'audit quest_difficulty_audit
--   2. Snapshot (INSERT audit) avant toute modification
--   3. Correction difficulty=5 → 4 sur les quêtes
--   4. Recalcul xp_reward / gold_reward sur les quêtes corrigées
--   5. Reversement du surplus XP/Gold sur player_stats (Supabase)
--   6. Ajout contrainte CHECK difficulty BETWEEN 1 AND 4
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Table d'audit (idempotent)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quest_difficulty_audit (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_id       uuid        NOT NULL,
  user_id        uuid        NOT NULL,
  old_difficulty integer     NOT NULL,
  new_difficulty integer     NOT NULL,
  xp_delta       integer     NOT NULL,  -- négatif = retrait d'XP
  gold_delta     integer     NOT NULL,  -- négatif = retrait d'or
  reason         text        NOT NULL,
  performed_at   timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────
-- 2. Snapshot avant modification (INSERT ignoré si déjà présent
--    grâce à DO NOTHING sur la contrainte unique ci-dessous)
-- ────────────────────────────────────────────────────────────
-- Contrainte unique pour rendre le snapshot idempotent :
-- si la migration était rejouée, les lignes d'audit ne se dupliquent pas.
ALTER TABLE quest_difficulty_audit
  ADD COLUMN IF NOT EXISTS migration_tag text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'quest_difficulty_audit'
      AND constraint_name = 'quest_difficulty_audit_quest_id_migration_tag_key'
  ) THEN
    ALTER TABLE quest_difficulty_audit
      ADD CONSTRAINT quest_difficulty_audit_quest_id_migration_tag_key
      UNIQUE (quest_id, migration_tag);
  END IF;
END;
$$;

INSERT INTO quest_difficulty_audit
  (quest_id, user_id, old_difficulty, new_difficulty, xp_delta, gold_delta, reason, migration_tag)
SELECT
  id,
  user_id,
  difficulty,
  4,
  -10,
  -25,
  'Bug DropdownButton/DifficultyPicker — difficulty 5 hors plage, corrigée à 4',
  '20260512100000'
FROM quests
WHERE difficulty = 5
ON CONFLICT (quest_id, migration_tag) DO NOTHING;

-- ────────────────────────────────────────────────────────────
-- 3. Correction difficulty : 5 → 4
-- ────────────────────────────────────────────────────────────
UPDATE quests
SET
  difficulty = 4,
  updated_at = now()
WHERE difficulty = 5;

-- ────────────────────────────────────────────────────────────
-- 4. Recalcul xp_reward / gold_reward sur les quêtes corrigées
--    Formule QuestRewardsCalculator : XP = 10 × diff, Gold = 25 × diff
--    difficulty=4 → xp_reward=40, gold_reward=100
--    (on corrige seulement les quêtes tracées dans l'audit)
-- ────────────────────────────────────────────────────────────
UPDATE quests
SET
  xp_reward   = xp_reward   + a.xp_delta,   -- xp_delta = -10
  gold_reward = gold_reward + a.gold_delta,  -- gold_delta = -25
  updated_at  = now()
FROM quest_difficulty_audit a
WHERE quests.id = a.quest_id
  AND a.migration_tag = '20260512100000';

-- ────────────────────────────────────────────────────────────
-- 5. Reversement du surplus sur player_stats (table Supabase)
--    Colonnes : experience (XP), gold
--    Surplus total = 3 quêtes × (-10 XP, -25 Gold) = (-30 XP, -75 Gold)
--    On regroupe par user_id pour gérer le cas multi-utilisateur
--    (en pratique 1 seul utilisateur, mais la requête est correcte
--     pour N utilisateurs).
-- ────────────────────────────────────────────────────────────
UPDATE player_stats ps
SET
  experience  = GREATEST(0, ps.experience + agg.total_xp_delta),
  gold        = GREATEST(0, ps.gold       + agg.total_gold_delta),
  updated_at  = now()
FROM (
  SELECT
    user_id,
    SUM(xp_delta)   AS total_xp_delta,
    SUM(gold_delta) AS total_gold_delta
  FROM quest_difficulty_audit
  WHERE migration_tag = '20260512100000'
  GROUP BY user_id
) agg
WHERE ps.user_id = agg.user_id;

-- ────────────────────────────────────────────────────────────
-- 6. Contrainte CHECK (non-idempotent — usage one-shot)
--    Si la migration est rejouée par erreur, l'ALTER échouera
--    avec "constraint already exists", ce qui est le comportement
--    souhaité (signal d'alerte).
-- ────────────────────────────────────────────────────────────
ALTER TABLE quests
  ADD CONSTRAINT difficulty_range CHECK (difficulty BETWEEN 1 AND 4);
