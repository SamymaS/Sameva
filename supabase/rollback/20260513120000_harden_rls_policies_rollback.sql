-- ============================================
-- Rollback : harden_rls_policies
-- Date     : 2026-05-13
-- Auteur   : Samy Boudaoud
-- Objet    : Restaure les policies RLS permissives d'origine
--            (telles que documentées dans l'audit RLS Phase A)
-- Usage    : À exécuter MANUELLEMENT dans le SQL Editor Supabase.
--            Ce fichier n'est PAS dans supabase/migrations/ pour éviter
--            une application automatique par `supabase db push`.
-- AVERTISSEMENT : Ce rollback NE restaure PAS la contrainte CHECK
--            legacy difficulty<=5 (suppression volontaire et définitive).
-- ============================================

BEGIN;

-- ============================================
-- Supprimer la vue leaderboard_view
-- ============================================
REVOKE SELECT ON public.leaderboard_view FROM authenticated;
DROP VIEW IF EXISTS public.leaderboard_view;

-- ============================================
-- quest_difficulty_audit : retirer RLS et policy
-- ============================================
DROP POLICY IF EXISTS "audit_service_role_access" ON public.quest_difficulty_audit;
ALTER TABLE public.quest_difficulty_audit DISABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.quest_difficulty_audit IS NULL;

-- ============================================
-- quests : retour aux policies permissives d'origine
-- ============================================
DROP POLICY IF EXISTS "quests_select_own" ON public.quests;
DROP POLICY IF EXISTS "quests_insert_own" ON public.quests;
DROP POLICY IF EXISTS "quests_update_own" ON public.quests;
DROP POLICY IF EXISTS "quests_delete_own" ON public.quests;

CREATE POLICY "Users can view own quests"
  ON public.quests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own quests"
  ON public.quests FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- player_stats : la policy d'origine était déjà correcte
--   (créée dans 20260224000000_player_stats.sql)
--   On la recrée telle quelle.
-- ============================================
DROP POLICY IF EXISTS "player_stats_self_access" ON public.player_stats;

CREATE POLICY "player_stats_self_access" ON player_stats
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- user_inventory : retour aux policies d'origine
-- ============================================
DROP POLICY IF EXISTS "user_inventory_select_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_insert_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_update_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_delete_own" ON public.user_inventory;

CREATE POLICY "Users can view own inventory"
  ON public.user_inventory FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own inventory"
  ON public.user_inventory FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- user_equipment : retour aux policies d'origine
-- ============================================
DROP POLICY IF EXISTS "user_equipment_select_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_insert_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_update_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_delete_own" ON public.user_equipment;

CREATE POLICY "Users can view own equipment"
  ON public.user_equipment FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own equipment"
  ON public.user_equipment FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- companions : retour aux policies d'origine
-- ============================================
DROP POLICY IF EXISTS "companions_select_own" ON public.companions;
DROP POLICY IF EXISTS "companions_insert_own" ON public.companions;
DROP POLICY IF EXISTS "companions_update_own" ON public.companions;
DROP POLICY IF EXISTS "companions_delete_own" ON public.companions;

CREATE POLICY "Users can view own companions"
  ON public.companions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own companions"
  ON public.companions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- users : retour aux policies d'origine
--   ATTENTION : la policy DELETE n'existait pas en origine.
--   Le rollback la supprime simplement.
-- ============================================
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_delete_own" ON public.users;

CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- items : retour à la policy d'origine
-- ============================================
DROP POLICY IF EXISTS "items_public_read" ON public.items;

CREATE POLICY "Authenticated users can view items"
  ON public.items FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- transactions : retour aux policies d'origine
--   (les policies originales ne spécifiaient pas TO authenticated
--    explicitement — elles ciblaient public implicitement)
-- ============================================
DROP POLICY IF EXISTS "transactions_select_own" ON public.transactions;
DROP POLICY IF EXISTS "transactions_insert_own" ON public.transactions;

CREATE POLICY "Users can view own transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

COMMIT;
