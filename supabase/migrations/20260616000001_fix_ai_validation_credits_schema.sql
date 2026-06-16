-- ============================================
-- Migration : fix ai_validation_credits — schéma conforme spec brique 2
-- Date     : 2026-06-16
-- Objet    : la migration 20260616000000 a appliqué un schéma erroné.
--            Table neuve et vide → DROP + recreate conforme.
--            Colonnes alignées sur le modèle client AiValidationState (brique 1).
--            is_premium / premium_until exclus (entitlement Phase 2).
-- ============================================

BEGIN;

-- Table vide créée par 20260616000000 avec un schéma incorrect → on la remplace.
DROP TABLE IF EXISTS public.ai_validation_credits;

CREATE TABLE public.ai_validation_credits (
  user_id                        UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  balance                        INTEGER     NOT NULL DEFAULT 0,
  last_daily_grant               TIMESTAMPTZ NULL,
  onboarding_granted             BOOLEAN     NOT NULL DEFAULT false,
  last_rewarded_streak_milestone INTEGER     NOT NULL DEFAULT 0,
  updated_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- RLS
-- ============================================
ALTER TABLE public.ai_validation_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai_credits_select_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_select_own" ON public.ai_validation_credits
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "ai_credits_insert_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_insert_own" ON public.ai_validation_credits
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "ai_credits_update_own" ON public.ai_validation_credits;
CREATE POLICY "ai_credits_update_own" ON public.ai_validation_credits
  FOR UPDATE TO authenticated
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Pas de policy DELETE (CASCADE depuis auth.users gère la RGPD).

-- ============================================
-- Trigger updated_at (réutilise la fonction générique existante)
-- ============================================
DROP TRIGGER IF EXISTS ai_validation_credits_updated_at ON public.ai_validation_credits;
CREATE TRIGGER ai_validation_credits_updated_at
  BEFORE UPDATE ON public.ai_validation_credits
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

COMMIT;
