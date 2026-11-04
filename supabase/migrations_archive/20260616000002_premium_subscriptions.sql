-- ============================================
-- Migration : premium_subscriptions — entitlement freemium Phase 2
-- Date     : 2026-06-16
-- Objet    : Table server-authoritative pour le statut premium.
--            Le client (authenticated) peut UNIQUEMENT LIRE sa propre ligne.
--            Les écritures sont réservées au webhook Stripe via service_role
--            (qui bypass la RLS). Aucune policy INSERT/UPDATE/DELETE
--            pour authenticated — c'est le cœur de la sécurité.
-- Réutilise : public.update_updated_at_column() créée en 20260616000001
-- ============================================

BEGIN;

-- ============================================
-- Table
-- ============================================
CREATE TABLE public.premium_subscriptions (
  user_id                 UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_premium              BOOLEAN     NOT NULL DEFAULT false,
  premium_until           TIMESTAMPTZ NULL,
  stripe_customer_id      TEXT        NULL,
  stripe_subscription_id  TEXT        NULL,
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- RLS — lecture seule pour le client authentifié
-- ============================================
ALTER TABLE public.premium_subscriptions ENABLE ROW LEVEL SECURITY;

-- Une seule policy : SELECT. Aucune policy d'écriture pour authenticated.
-- Forme (select auth.uid()) pour éviter le WARN auth_rls_initplan.
CREATE POLICY "premium_select_own" ON public.premium_subscriptions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ============================================
-- Trigger updated_at — RÉUTILISE la fonction générique existante
-- ============================================
DROP TRIGGER IF EXISTS premium_subscriptions_updated_at ON public.premium_subscriptions;
CREATE TRIGGER premium_subscriptions_updated_at
  BEFORE UPDATE ON public.premium_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

COMMIT;
