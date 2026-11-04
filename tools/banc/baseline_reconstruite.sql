-- Baseline du banc d'essai : PHOTOGRAPHIE DE LA PRODUCTION (4 novembre 2026).
-- Tables créées depuis le dashboard (aucune migration ne les décrit), reproduites
-- à l'identique depuis le catalogue de la base de production : types énumérés,
-- colonnes, valeurs par défaut, contraintes, index, déclencheurs, RLS et politiques.
-- Généré par lecture du catalogue ; ne pas modifier à la main sans revérifier la prod.

-- Types énumérés
DO $$ BEGIN CREATE TYPE public.item_type AS ENUM ('weapon', 'armor', 'helmet', 'shield', 'outfit', 'aura', 'potion', 'consumable', 'cosmetic', 'companion', 'material'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quest_frequency AS ENUM ('one_off', 'daily', 'weekly', 'monthly'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.quest_status AS ENUM ('active', 'completed', 'failed', 'archived'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.rarity_tier AS ENUM ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE public.validation_type AS ENUM ('manual', 'photo', 'timer', 'geolocation'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Fonctions utilitaires d'origine
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.experience_for_level(level integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  RETURN (100 * (level * 1.5))::INTEGER;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.users (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  );
  INSERT INTO public.user_equipment (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$function$;


CREATE TABLE IF NOT EXISTS public.users (
  id uuid NOT NULL,
  username text,
  display_name text,
  avatar_url text,
  level integer DEFAULT 1 NOT NULL,
  experience integer DEFAULT 0 NOT NULL,
  gold integer DEFAULT 0 NOT NULL,
  crystals integer DEFAULT 0 NOT NULL,
  health_points integer DEFAULT 100 NOT NULL,
  max_health_points integer DEFAULT 100 NOT NULL,
  credibility_score double precision DEFAULT 1.0 NOT NULL,
  streak integer DEFAULT 0 NOT NULL,
  last_active_date timestamptz,
  settings jsonb DEFAULT '{}'::jsonb,
  achievements jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.items (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  description text,
  type public.item_type NOT NULL,
  rarity public.rarity_tier DEFAULT 'common'::rarity_tier NOT NULL,
  image_path text,
  attack_bonus integer DEFAULT 0,
  defense_bonus integer DEFAULT 0,
  health_bonus integer DEFAULT 0,
  experience_bonus integer DEFAULT 0,
  gold_bonus integer DEFAULT 0,
  value integer DEFAULT 0 NOT NULL,
  is_equippable boolean DEFAULT false NOT NULL,
  is_consumable boolean DEFAULT false NOT NULL,
  stack_size integer DEFAULT 1 NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.quests (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  category text NOT NULL,
  difficulty integer NOT NULL,
  rarity public.rarity_tier DEFAULT 'common'::rarity_tier NOT NULL,
  frequency public.quest_frequency DEFAULT 'one_off'::quest_frequency NOT NULL,
  estimated_duration_minutes integer DEFAULT 0,
  xp_reward integer DEFAULT 0,
  gold_reward integer DEFAULT 0,
  validation_type public.validation_type DEFAULT 'manual'::validation_type NOT NULL,
  proof_data text,
  is_completed boolean DEFAULT false NOT NULL,
  status public.quest_status DEFAULT 'active'::quest_status NOT NULL,
  sub_quests text[] DEFAULT ARRAY[]::text[],
  created_at timestamptz DEFAULT now() NOT NULL,
  deadline timestamptz,
  completed_at timestamptz,
  updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.companions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  name text NOT NULL,
  mood integer DEFAULT 100 NOT NULL,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL,
  race text DEFAULT 'michi'::text NOT NULL,
  rarity text DEFAULT 'common'::text NOT NULL,
  is_main boolean DEFAULT false NOT NULL,
  equipped_hat text,
  equipped_outfit_cosmetic text,
  equipped_pants text,
  equipped_shoes text,
  equipped_aura text,
  equipped_accessory text,
  equipped_title text
);

CREATE TABLE IF NOT EXISTS public.user_inventory (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  item_id uuid NOT NULL,
  quantity integer DEFAULT 1 NOT NULL,
  is_equipped boolean DEFAULT false,
  acquired_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.user_equipment (
  user_id uuid NOT NULL,
  weapon_id uuid,
  armor_id uuid,
  helmet_id uuid,
  shield_id uuid,
  outfit_id uuid,
  aura_id uuid,
  updated_at timestamptz DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  user_id uuid NOT NULL,
  type text NOT NULL,
  item_id uuid,
  quantity integer DEFAULT 1 NOT NULL,
  gold_amount integer DEFAULT 0 NOT NULL,
  crystals_amount integer DEFAULT 0 NOT NULL,
  description text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Contraintes
ALTER TABLE public.users ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE public.items ADD CONSTRAINT items_pkey PRIMARY KEY (id);
ALTER TABLE public.user_inventory ADD CONSTRAINT user_inventory_quantity_check CHECK ((quantity > 0));
ALTER TABLE public.user_inventory ADD CONSTRAINT user_inventory_pkey PRIMARY KEY (id);
ALTER TABLE public.user_inventory ADD CONSTRAINT user_inventory_user_id_item_id_key UNIQUE (user_id, item_id);
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_pkey PRIMARY KEY (user_id);
ALTER TABLE public.companions ADD CONSTRAINT companions_pkey PRIMARY KEY (id);
ALTER TABLE public.quests ADD CONSTRAINT quests_pkey PRIMARY KEY (id);
ALTER TABLE public.transactions ADD CONSTRAINT transactions_type_check CHECK ((type = ANY (ARRAY['purchase'::text, 'sale'::text, 'reward'::text, 'quest_completion'::text, 'gift'::text])));
ALTER TABLE public.transactions ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);
-- (créé par une migration) ALTER TABLE public.quests ADD CONSTRAINT difficulty_range CHECK (((difficulty >= 1) AND (difficulty <= 4)));
-- (créé par une migration) ALTER TABLE public.companions ADD CONSTRAINT companions_race_check CHECK ((race = ANY (ARRAY['michi'::text, 'lune'::text, 'braise'::text, 'neige'::text, 'cosmos'::text, 'sakura'::text])));
-- (créé par une migration) ALTER TABLE public.companions ADD CONSTRAINT companions_rarity_check CHECK ((rarity = ANY (ARRAY['common'::text, 'uncommon'::text, 'rare'::text, 'veryRare'::text, 'epic'::text, 'legendary'::text, 'mythic'::text])));
ALTER TABLE public.users ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.user_inventory ADD CONSTRAINT user_inventory_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.user_inventory ADD CONSTRAINT user_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_weapon_id_fkey FOREIGN KEY (weapon_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_armor_id_fkey FOREIGN KEY (armor_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_helmet_id_fkey FOREIGN KEY (helmet_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_shield_id_fkey FOREIGN KEY (shield_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_outfit_id_fkey FOREIGN KEY (outfit_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.user_equipment ADD CONSTRAINT user_equipment_aura_id_fkey FOREIGN KEY (aura_id) REFERENCES items(id) ON DELETE SET NULL;
ALTER TABLE public.companions ADD CONSTRAINT companions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.quests ADD CONSTRAINT quests_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.transactions ADD CONSTRAINT transactions_item_id_fkey FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL;

-- Index
CREATE INDEX IF NOT EXISTS idx_quests_user ON public.quests USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_users_level ON public.users USING btree (level);
CREATE INDEX IF NOT EXISTS idx_items_type ON public.items USING btree (type);
-- (créé par une migration) CREATE INDEX IF NOT EXISTS idx_companions_user_main ON public.companions USING btree (user_id, is_main) WHERE (is_main = true);

-- Déclencheurs
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON public.user_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_companions_updated_at BEFORE UPDATE ON public.companions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_quests_updated_at BEFORE UPDATE ON public.quests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RLS et politiques
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
-- (créée par une migration) CREATE POLICY "quests_delete_own" ON public.quests AS PERMISSIVE FOR DELETE TO authenticat
-- (créée par une migration) CREATE POLICY "quests_insert_own" ON public.quests AS PERMISSIVE FOR INSERT TO authenticat
-- (créée par une migration) CREATE POLICY "quests_select_own" ON public.quests AS PERMISSIVE FOR SELECT TO authenticat
-- (créée par une migration) CREATE POLICY "quests_update_own" ON public.quests AS PERMISSIVE FOR UPDATE TO authenticat
-- (créée par une migration) CREATE POLICY "users_delete_own" ON public.users AS PERMISSIVE FOR DELETE TO authenticated
-- (créée par une migration) CREATE POLICY "users_insert_own" ON public.users AS PERMISSIVE FOR INSERT TO authenticated
-- (créée par une migration) CREATE POLICY "users_select_own" ON public.users AS PERMISSIVE FOR SELECT TO authenticated
-- (créée par une migration) CREATE POLICY "users_update_own" ON public.users AS PERMISSIVE FOR UPDATE TO authenticated
-- (créée par une migration) CREATE POLICY "items_public_read" ON public.items AS PERMISSIVE FOR SELECT TO authenticate
-- (créée par une migration) CREATE POLICY "user_inventory_delete_own" ON public.user_inventory AS PERMISSIVE FOR DELET
-- (créée par une migration) CREATE POLICY "user_inventory_insert_own" ON public.user_inventory AS PERMISSIVE FOR INSER
-- (créée par une migration) CREATE POLICY "user_inventory_select_own" ON public.user_inventory AS PERMISSIVE FOR SELEC
-- (créée par une migration) CREATE POLICY "user_inventory_update_own" ON public.user_inventory AS PERMISSIVE FOR UPDAT
-- (créée par une migration) CREATE POLICY "user_equipment_delete_own" ON public.user_equipment AS PERMISSIVE FOR DELET
-- (créée par une migration) CREATE POLICY "user_equipment_insert_own" ON public.user_equipment AS PERMISSIVE FOR INSER
-- (créée par une migration) CREATE POLICY "user_equipment_select_own" ON public.user_equipment AS PERMISSIVE FOR SELEC
-- (créée par une migration) CREATE POLICY "user_equipment_update_own" ON public.user_equipment AS PERMISSIVE FOR UPDAT
-- (créée par une migration) CREATE POLICY "transactions_insert_own" ON public.transactions AS PERMISSIVE FOR INSERT TO
-- (créée par une migration) CREATE POLICY "transactions_select_own" ON public.transactions AS PERMISSIVE FOR SELECT TO
-- (créée par une migration) CREATE POLICY "companions_delete_own" ON public.companions AS PERMISSIVE FOR DELETE TO aut
-- (créée par une migration) CREATE POLICY "companions_insert_own" ON public.companions AS PERMISSIVE FOR INSERT TO aut
-- (créée par une migration) CREATE POLICY "companions_select_own" ON public.companions AS PERMISSIVE FOR SELECT TO aut
-- (créée par une migration) CREATE POLICY "companions_update_own" ON public.companions AS PERMISSIVE FOR UPDATE TO aut
