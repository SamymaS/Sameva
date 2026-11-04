-- ============================================
-- Migration : ai_validation_credits
-- Date     : 2026-06-16
-- Auteur   : Samy Boudaoud
-- Objet    : Table de crédits IA pour MougiBot (analyze-quest-proof)
--            - Fonction générique update_updated_at_column() (réutilisable)
--            - Table ai_validation_credits (additive, sans impact sur l'existant)
--            - RLS activée avec 3 policies authenticated (SELECT/INSERT/UPDATE)
--              Pas de DELETE : les crédits sont des données comptables immuables
--            - Trigger BEFORE UPDATE pour updated_at automatique
-- ============================================

BEGIN;

-- ============================================
-- 1. Fonction générique updated_at (distincte de update_player_stats_updated_at)
--    Réutilisable pour toute table disposant d'une colonne updated_at.
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at_column() IS
  'Fonction trigger générique : met à jour updated_at = NOW() avant chaque UPDATE. '
  'Distincte de update_player_stats_updated_at() qui est couplée à player_stats.';

-- ============================================
-- 2. Table ai_validation_credits
--    Une ligne par utilisateur.
--    credits_remaining  : crédits IA disponibles (décrémentés à chaque validation)
--    credits_used_total : compteur cumulatif (jamais décrémenté, audit)
--    last_reset_at      : dernière remise à zéro (rechargement mensuel, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_validation_credits (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  credits_remaining   INT         NOT NULL DEFAULT 10 CHECK (credits_remaining >= 0),
  credits_used_total  INT         NOT NULL DEFAULT 0  CHECK (credits_used_total >= 0),
  last_reset_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ai_validation_credits_user_unique UNIQUE (user_id)
);

COMMENT ON TABLE public.ai_validation_credits IS
  'Crédits IA par utilisateur pour la validation MougiBot (Edge Function analyze-quest-proof). '
  'Une ligne par user. credits_remaining : solde courant. credits_used_total : compteur cumulatif immuable (audit). '
  'Pas de policy DELETE : les lignes sont des données comptables, suppression interdite aux clients.';

COMMENT ON COLUMN public.ai_validation_credits.credits_remaining IS
  'Solde de crédits IA disponibles. Décrémenté par la Edge Function après chaque validation réussie. Constraint >= 0.';

COMMENT ON COLUMN public.ai_validation_credits.credits_used_total IS
  'Compteur cumulatif de crédits consommés. Jamais décrémenté. Utilisé pour audit et statistiques.';

COMMENT ON COLUMN public.ai_validation_credits.last_reset_at IS
  'Timestamp de la dernière remise à zéro des crédits (rechargement mensuel ou administratif).';

-- Index sur user_id (lookup unique mais utile pour les jointures et le monitoring)
CREATE INDEX IF NOT EXISTS ai_validation_credits_user_id_idx
  ON public.ai_validation_credits (user_id);

-- Index sur updated_at pour le monitoring et les requêtes d'audit temporelles
CREATE INDEX IF NOT EXISTS ai_validation_credits_updated_at_idx
  ON public.ai_validation_credits (updated_at DESC);

-- ============================================
-- 3. Row Level Security
-- ============================================
ALTER TABLE public.ai_validation_credits ENABLE ROW LEVEL SECURITY;

-- SELECT : chaque utilisateur ne voit que ses propres crédits
DROP POLICY IF EXISTS "ai_credits_select_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_select_own" ON public.ai_validation_credits
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- INSERT : chaque utilisateur ne peut insérer que sa propre ligne
DROP POLICY IF EXISTS "ai_credits_insert_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_insert_own" ON public.ai_validation_credits
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE : chaque utilisateur ne peut modifier que ses propres crédits
DROP POLICY IF EXISTS "ai_credits_update_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_update_own" ON public.ai_validation_credits
  FOR UPDATE TO authenticated
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Pas de policy DELETE volontairement — les crédits sont des données comptables.
-- La suppression d'une ligne ne peut se faire que via service_role (admin).

-- ============================================
-- 4. Trigger updated_at
-- ============================================
DROP TRIGGER IF EXISTS ai_validation_credits_updated_at
  ON public.ai_validation_credits;

CREATE TRIGGER ai_validation_credits_updated_at
  BEFORE UPDATE ON public.ai_validation_credits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

COMMIT;
