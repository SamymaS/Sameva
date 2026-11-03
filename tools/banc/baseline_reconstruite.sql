-- Reconstitution des tables créées hors migrations (dashboard), d'après le code Dart.
-- BANC D'ESSAI UNIQUEMENT : remplacée par la vraie baseline (supabase db pull) au Sprint 0.
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text, display_name text, avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.quests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL, description text,
  estimated_duration_minutes int NOT NULL DEFAULT 0,
  frequency text NOT NULL DEFAULT 'one_off',
  difficulty int NOT NULL DEFAULT 1,
  category text NOT NULL DEFAULT 'Autre',
  rarity text NOT NULL DEFAULT 'common',
  sub_quests jsonb DEFAULT '[]'::jsonb,
  is_completed boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active',
  validation_type text NOT NULL DEFAULT 'manual',
  xp_reward int, gold_reward int, proof_data text,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz, deadline timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.user_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id text, quantity int NOT NULL DEFAULT 1);
ALTER TABLE public.user_inventory ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.user_equipment (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  weapon text, armor text, helmet text, accessory text);
ALTER TABLE public.user_equipment ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT 'Mougi', created_at timestamptz NOT NULL DEFAULT now(),
  level int, experience int, health_points int, max_health_points int,
  description text, image_path text, equipped_outfit_id text);
ALTER TABLE public.companions ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.items (id text PRIMARY KEY, name text, rarity text);
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount int, currency text, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
