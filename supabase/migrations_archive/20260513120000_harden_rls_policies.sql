-- ============================================
-- Migration : harden_rls_policies
-- Date     : 2026-05-13
-- Auteur   : Samy Boudaoud
-- Objet    : Durcissement RLS sur toutes tables sensibles + cleanup
--            - Roles {public} → {authenticated} partout
--            - Policies ALL → 4 policies CRUD séparées avec WITH CHECK
--            - Vue leaderboard_view (colonnes non-sensibles)
--            - Table d'audit admin sécurisée (service_role only)
--            - DROP contrainte CHECK legacy difficulty IN (1,5)
--            - Activation RLS sur quest_difficulty_audit
-- ============================================

BEGIN;

-- ============================================
-- 0. quests : DROP contrainte CHECK legacy (difficulty <= 5)
--    La contrainte difficulty_range (BETWEEN 1 AND 4) ajoutée par
--    20260512100000 reste en place.
-- ============================================
DO $$
DECLARE
  c_name text;
BEGIN
  SELECT conname INTO c_name
  FROM pg_constraint
  WHERE conrelid = 'public.quests'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%difficulty%5%'
    AND pg_get_constraintdef(oid) NOT LIKE '%difficulty_range%';
  IF c_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.quests DROP CONSTRAINT %I', c_name);
    RAISE NOTICE 'Contrainte CHECK legacy supprimée : %', c_name;
  ELSE
    RAISE NOTICE 'Aucune contrainte CHECK legacy difficulty<=5 trouvée (déjà absente ou déjà supprimée).';
  END IF;
END $$;

-- ============================================
-- 1. quest_difficulty_audit : activer RLS + policy service_role + commentaire
-- ============================================
ALTER TABLE public.quest_difficulty_audit ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.quest_difficulty_audit IS
  'Table d''audit admin uniquement. RLS activée intentionnellement sans policy utilisateur. Accès via service_role (bypass RLS Supabase natif) ou dashboard admin.';

DROP POLICY IF EXISTS "audit_service_role_access" ON public.quest_difficulty_audit;
CREATE POLICY "audit_service_role_access" ON public.quest_difficulty_audit
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================
-- 2. quests : 4 policies CRUD séparées, authenticated, WITH CHECK
-- ============================================
DROP POLICY IF EXISTS "Enable all for users based on user_id" ON public.quests;
DROP POLICY IF EXISTS "Users can view their own quests" ON public.quests;
DROP POLICY IF EXISTS "Users can insert their own quests" ON public.quests;
DROP POLICY IF EXISTS "Users can update their own quests" ON public.quests;
DROP POLICY IF EXISTS "Users can delete their own quests" ON public.quests;
DROP POLICY IF EXISTS "Users can manage own quests" ON public.quests;
DROP POLICY IF EXISTS "Users can view own quests" ON public.quests;
DROP POLICY IF EXISTS "quests_select_own" ON public.quests;
DROP POLICY IF EXISTS "quests_insert_own" ON public.quests;
DROP POLICY IF EXISTS "quests_update_own" ON public.quests;
DROP POLICY IF EXISTS "quests_delete_own" ON public.quests;

CREATE POLICY "quests_select_own" ON public.quests
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "quests_insert_own" ON public.quests
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quests_update_own" ON public.quests
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "quests_delete_own" ON public.quests
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- 3. player_stats + vue leaderboard_view
-- ============================================
-- La policy "player_stats_self_access" créée dans 20260224000000 est déjà
-- correcte (ALL, authenticated, USING + WITH CHECK). On la recrée proprement
-- pour garantir la cohérence (DROP IF EXISTS = idempotent).
DROP POLICY IF EXISTS "leaderboard_read_player_stats" ON public.player_stats;
DROP POLICY IF EXISTS "Lecture leaderboard player_stats" ON public.player_stats;
DROP POLICY IF EXISTS "player_stats_self_access" ON public.player_stats;

CREATE POLICY "player_stats_self_access" ON public.player_stats
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Vue leaderboard restreinte (colonnes non-sensibles uniquement).
-- security_barrier = true : empêche les fonctions volatiles de l'appelant
--   de court-circuiter les filtres de la vue (protection fuite de données).
-- security_invoker = false (défaut PG 15+) : la vue s'exécute avec les droits
--   du propriétaire (postgres), bypasse les RLS de player_stats → toutes les
--   lignes sont remontées pour les users authenticated. C'est le comportement
--   voulu pour un classement multi-joueurs.
-- Colonnes exposées : user_id, level, xp (alias de experience), streak,
--   display_name. gold/crystals/health/credibility_score/moral ne sont PAS
--   inclus → pas de fuite de données sensibles.
-- Note : 'experience' aliasé en 'xp' ; le repository Dart lit le champ 'xp'.
DROP VIEW IF EXISTS public.leaderboard_view;

CREATE VIEW public.leaderboard_view
  WITH (security_barrier = true, security_invoker = false) AS
  SELECT
    ps.user_id,
    ps.level,
    ps.experience AS xp,
    ps.streak,
    COALESCE(u.display_name, u.username, 'Aventurier') AS display_name
  FROM public.player_stats ps
  JOIN public.users u ON u.id = ps.user_id;

ALTER VIEW public.leaderboard_view OWNER TO postgres;

GRANT SELECT ON public.leaderboard_view TO authenticated;

COMMENT ON VIEW public.leaderboard_view IS
  'Vue publique du classement. Bypass volontaire des RLS de player_stats via security_barrier + security_invoker=false pour exposer uniquement les colonnes publiques (level, xp, streak, display_name) sans fuiter gold/crystals/health/credibility_score/moral.';

-- ============================================
-- 4. user_inventory : 4 policies CRUD séparées, authenticated, WITH CHECK
-- ============================================
DROP POLICY IF EXISTS "Enable all for users based on user_id" ON public.user_inventory;
DROP POLICY IF EXISTS "Users can manage their own inventory" ON public.user_inventory;
DROP POLICY IF EXISTS "Users can view own inventory" ON public.user_inventory;
DROP POLICY IF EXISTS "Users can manage own inventory" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_self_access" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_select_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_insert_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_update_own" ON public.user_inventory;
DROP POLICY IF EXISTS "user_inventory_delete_own" ON public.user_inventory;

CREATE POLICY "user_inventory_select_own" ON public.user_inventory
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "user_inventory_insert_own" ON public.user_inventory
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_inventory_update_own" ON public.user_inventory
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_inventory_delete_own" ON public.user_inventory
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- 5. user_equipment : 4 policies CRUD séparées, authenticated, WITH CHECK
--    PK = user_id (une ligne par utilisateur), pas de colonne séparée user_id.
-- ============================================
DROP POLICY IF EXISTS "Enable all for users based on user_id" ON public.user_equipment;
DROP POLICY IF EXISTS "Users can view own equipment" ON public.user_equipment;
DROP POLICY IF EXISTS "Users can manage own equipment" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_self_access" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_select_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_insert_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_update_own" ON public.user_equipment;
DROP POLICY IF EXISTS "user_equipment_delete_own" ON public.user_equipment;

CREATE POLICY "user_equipment_select_own" ON public.user_equipment
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "user_equipment_insert_own" ON public.user_equipment
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_equipment_update_own" ON public.user_equipment
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_equipment_delete_own" ON public.user_equipment
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- 6. companions : 4 policies CRUD séparées, authenticated, WITH CHECK
-- ============================================
DROP POLICY IF EXISTS "Users can view own companions" ON public.companions;
DROP POLICY IF EXISTS "Users can manage own companions" ON public.companions;
DROP POLICY IF EXISTS "companions_self_access" ON public.companions;
DROP POLICY IF EXISTS "companions_select_own" ON public.companions;
DROP POLICY IF EXISTS "companions_insert_own" ON public.companions;
DROP POLICY IF EXISTS "companions_update_own" ON public.companions;
DROP POLICY IF EXISTS "companions_delete_own" ON public.companions;

CREATE POLICY "companions_select_own" ON public.companions
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "companions_insert_own" ON public.companions
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "companions_update_own" ON public.companions
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "companions_delete_own" ON public.companions
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- 7. users : 4 policies CRUD séparées, authenticated, WITH CHECK
--    Inclut DELETE (activé selon décision utilisateur).
-- ============================================
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_delete_own" ON public.users;
DROP POLICY IF EXISTS "users_read_public_profiles" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON public.users;

CREATE POLICY "users_select_own" ON public.users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_delete_own" ON public.users
  FOR DELETE TO authenticated
  USING (auth.uid() = id);

-- ============================================
-- 8. items : catalogue public, lecture authenticated uniquement
-- ============================================
DROP POLICY IF EXISTS "items_public_read" ON public.items;
DROP POLICY IF EXISTS "Public read items" ON public.items;
DROP POLICY IF EXISTS "Authenticated users can view items" ON public.items;

CREATE POLICY "items_public_read" ON public.items
  FOR SELECT TO authenticated
  USING (true);

-- ============================================
-- 9. transactions : durcissement role {public} → {authenticated}
-- ============================================
DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
DROP POLICY IF EXISTS "transactions_insert_own" ON public.transactions;
DROP POLICY IF EXISTS "transactions_select_own" ON public.transactions;

CREATE POLICY "transactions_select_own" ON public.transactions
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "transactions_insert_own" ON public.transactions
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

COMMIT;
