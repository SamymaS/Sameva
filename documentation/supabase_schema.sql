-- ============================================
-- SCHÉMA SQL POUR SUPABASE - SAMEVA
-- ============================================
-- Ce fichier contient toutes les tables nécessaires pour l'application Sameva
-- À exécuter dans l'éditeur SQL de Supabase
-- ============================================

-- ============================================
-- 1. TYPES ENUM
-- ============================================

-- Type d'item
CREATE TYPE item_type AS ENUM (
  'weapon',
  'armor',
  'helmet',
  'shield',
  'potion',
  'consumable',
  'cosmetic',
  'companion',
  'material'
);

-- Rareté d'item
CREATE TYPE item_rarity AS ENUM (
  'common',
  'uncommon',
  'rare',
  'veryRare',
  'epic',
  'legendary',
  'mythic'
);

-- Rareté de quête
CREATE TYPE quest_rarity AS ENUM (
  'common',
  'uncommon',
  'rare',
  'veryRare',
  'epic',
  'legendary',
  'mythic'
);

-- Fréquence de quête
CREATE TYPE quest_frequency AS ENUM (
  'once',
  'daily',
  'weekly',
  'monthly'
);

-- Statut de quête
CREATE TYPE quest_status AS ENUM (
  'active',
  'completed',
  'failed',
  'archived'
);

-- ============================================
-- 2. TABLE: users (Extension de auth.users)
-- ============================================

CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  level INTEGER NOT NULL DEFAULT 1,
  experience INTEGER NOT NULL DEFAULT 0,
  gold INTEGER NOT NULL DEFAULT 0,
  crystals INTEGER NOT NULL DEFAULT 0,
  health_points INTEGER NOT NULL DEFAULT 100,
  max_health_points INTEGER NOT NULL DEFAULT 100,
  credibility_score DOUBLE PRECISION NOT NULL DEFAULT 1.0,
  moral DOUBLE PRECISION NOT NULL DEFAULT 1.0 CHECK (moral >= 0.0 AND moral <= 1.0),
  streak INTEGER NOT NULL DEFAULT 0,
  last_active_date TIMESTAMPTZ,
  achievements JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour les performances
CREATE INDEX idx_users_level ON public.users(level);
CREATE INDEX idx_users_streak ON public.users(streak);

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 3. TABLE: items (Catalogue d'items)
-- ============================================

CREATE TABLE public.items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  type item_type NOT NULL,
  rarity item_rarity NOT NULL,
  image_path TEXT,
  attack_bonus INTEGER DEFAULT 0,
  defense_bonus INTEGER DEFAULT 0,
  health_bonus INTEGER DEFAULT 0,
  experience_bonus INTEGER DEFAULT 0,
  gold_bonus INTEGER DEFAULT 0,
  value INTEGER NOT NULL DEFAULT 0,
  is_equippable BOOLEAN NOT NULL DEFAULT false,
  is_consumable BOOLEAN NOT NULL DEFAULT false,
  stack_size INTEGER NOT NULL DEFAULT 1,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_items_type ON public.items(type);
CREATE INDEX idx_items_rarity ON public.items(rarity);
CREATE INDEX idx_items_equippable ON public.items(is_equippable);

-- ============================================
-- 4. TABLE: user_inventory (Inventaire des joueurs)
-- ============================================

CREATE TABLE public.user_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);

-- Index
CREATE INDEX idx_inventory_user ON public.user_inventory(user_id);
CREATE INDEX idx_inventory_item ON public.user_inventory(item_id);

-- ============================================
-- 5. TABLE: user_equipment (Équipement actuel)
-- ============================================

CREATE TABLE public.user_equipment (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  weapon_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  armor_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  helmet_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  shield_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  outfit_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  aura_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER update_equipment_updated_at
  BEFORE UPDATE ON public.user_equipment
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. TABLE: companions (Compagnons des joueurs)
-- ============================================

CREATE TABLE public.companions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  image_path TEXT,
  level INTEGER NOT NULL DEFAULT 1,
  experience INTEGER NOT NULL DEFAULT 0,
  health_points INTEGER NOT NULL DEFAULT 100,
  max_health_points INTEGER NOT NULL DEFAULT 100,
  equipped_outfit_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_companions_user ON public.companions(user_id);

CREATE TRIGGER update_companions_updated_at
  BEFORE UPDATE ON public.companions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. TABLE: quests (Quêtes des joueurs)
-- ============================================

CREATE TABLE public.quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  estimated_duration_minutes INTEGER NOT NULL DEFAULT 0,
  frequency quest_frequency NOT NULL,
  difficulty INTEGER NOT NULL CHECK (difficulty >= 1 AND difficulty <= 5),
  category TEXT NOT NULL,
  rarity quest_rarity NOT NULL,
  sub_quests TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_completed BOOLEAN NOT NULL DEFAULT false,
  status quest_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  deadline TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_quests_user ON public.quests(user_id);
CREATE INDEX idx_quests_status ON public.quests(status);
CREATE INDEX idx_quests_completed ON public.quests(is_completed);
CREATE INDEX idx_quests_created ON public.quests(created_at);

CREATE TRIGGER update_quests_updated_at
  BEFORE UPDATE ON public.quests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. TABLE: transactions (Historique des transactions)
-- ============================================

CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('purchase', 'sale', 'reward', 'quest_completion', 'gift')),
  item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  gold_amount INTEGER NOT NULL DEFAULT 0,
  crystals_amount INTEGER NOT NULL DEFAULT 0,
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_transactions_user ON public.transactions(user_id);
CREATE INDEX idx_transactions_type ON public.transactions(type);
CREATE INDEX idx_transactions_created ON public.transactions(created_at);

-- ============================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 10. POLICIES RLS
-- ============================================

-- Users: Les utilisateurs peuvent voir et modifier uniquement leur propre profil
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Items: Tous les utilisateurs authentifiés peuvent voir les items
CREATE POLICY "Authenticated users can view items"
  ON public.items FOR SELECT
  TO authenticated
  USING (true);

-- User Inventory: Les utilisateurs peuvent voir et modifier uniquement leur inventaire
CREATE POLICY "Users can view own inventory"
  ON public.user_inventory FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own inventory"
  ON public.user_inventory FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- User Equipment: Les utilisateurs peuvent voir et modifier uniquement leur équipement
CREATE POLICY "Users can view own equipment"
  ON public.user_equipment FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own equipment"
  ON public.user_equipment FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Companions: Les utilisateurs peuvent voir et modifier uniquement leurs compagnons
CREATE POLICY "Users can view own companions"
  ON public.companions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own companions"
  ON public.companions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Quests: Les utilisateurs peuvent voir et modifier uniquement leurs quêtes
CREATE POLICY "Users can view own quests"
  ON public.quests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own quests"
  ON public.quests FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Transactions: Les utilisateurs peuvent voir uniquement leurs transactions
CREATE POLICY "Users can view own transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 11. FONCTIONS UTILITAIRES
-- ============================================

-- Fonction pour créer automatiquement un profil utilisateur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  );
  
  -- Créer l'équipement vide
  INSERT INTO public.user_equipment (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer automatiquement le profil à l'inscription
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Fonction pour calculer l'expérience nécessaire pour un niveau
CREATE OR REPLACE FUNCTION public.experience_for_level(level INTEGER)
RETURNS INTEGER AS $$
BEGIN
  RETURN (100 * (level * 1.5))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 12. DONNÉES INITIALES (Items de base)
-- ============================================

-- Vous pouvez ajouter des items de base ici si nécessaire
-- Exemple :
-- INSERT INTO public.items (name, description, type, rarity, value, is_equippable) VALUES
-- ('Épée en bois', 'Une simple épée en bois', 'weapon', 'common', 50, true);

-- ============================================
-- FIN DU SCHÉMA
-- ============================================



