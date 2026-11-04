-- =============================================================================
-- Baseline : le schéma de production juste avant le Sprint 1.
-- =============================================================================
-- Les tables d'origine (users, quests, companions, items, user_inventory,
-- user_equipment, transactions) ont été créées depuis le dashboard : aucune
-- migration ne les décrivait. Cette baseline remplace les migrations de février
-- à juin 2026 (archivées dans supabase/migrations_archive/) et reproduit à
-- l'identique le schéma public de la production au moment du Sprint 1 :
-- types énumérés, tables, contraintes, index, déclencheurs, RLS, politiques
-- et droits. Elle est suivie des migrations du Sprint 1 et du Sprint 2.
--
-- Vérifié le 4 novembre 2026 : baseline + migrations S1/S2 donne un catalogue
-- identique à celui de la production (colonnes, contraintes, index,
-- politiques, déclencheurs, fonctions, vues, droits).
-- =============================================================================

--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

--
-- Name: item_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.item_type AS ENUM (
    'weapon',
    'armor',
    'helmet',
    'shield',
    'outfit',
    'aura',
    'potion',
    'consumable',
    'cosmetic',
    'companion',
    'material'
);

--
-- Name: quest_frequency; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quest_frequency AS ENUM (
    'one_off',
    'daily',
    'weekly',
    'monthly'
);

--
-- Name: quest_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.quest_status AS ENUM (
    'active',
    'completed',
    'failed',
    'archived'
);

--
-- Name: rarity_tier; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rarity_tier AS ENUM (
    'common',
    'uncommon',
    'rare',
    'epic',
    'legendary',
    'mythic'
);

--
-- Name: validation_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.validation_type AS ENUM (
    'manual',
    'photo',
    'timer',
    'geolocation'
);

--
-- Name: experience_for_level(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.experience_for_level(level integer) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
  RETURN (100 * (level * 1.5))::INTEGER;
END;
$$;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;

--
-- Name: update_player_stats_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_player_stats_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
  END;
  $$;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

--
-- Name: FUNCTION update_updated_at_column(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.update_updated_at_column() IS 'Fonction trigger générique : met à jour updated_at = NOW() avant chaque UPDATE. Distincte de update_player_stats_updated_at() qui est couplée à player_stats.';

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_validation_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_validation_credits (
    user_id uuid NOT NULL,
    balance integer DEFAULT 0 NOT NULL,
    last_daily_grant timestamp with time zone,
    onboarding_granted boolean DEFAULT false NOT NULL,
    last_rewarded_streak_milestone integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: companions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name text NOT NULL,
    mood integer DEFAULT 100 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    race text DEFAULT 'michi'::text NOT NULL,
    rarity text DEFAULT 'common'::text NOT NULL,
    is_main boolean DEFAULT false NOT NULL,
    equipped_hat text,
    equipped_outfit_cosmetic text,
    equipped_pants text,
    equipped_shoes text,
    equipped_aura text,
    equipped_accessory text,
    equipped_title text,
    CONSTRAINT companions_race_check CHECK ((race = ANY (ARRAY['michi'::text, 'lune'::text, 'braise'::text, 'neige'::text, 'cosmos'::text, 'sakura'::text]))),
    CONSTRAINT companions_rarity_check CHECK ((rarity = ANY (ARRAY['common'::text, 'uncommon'::text, 'rare'::text, 'veryRare'::text, 'epic'::text, 'legendary'::text, 'mythic'::text])))
);

--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    type public.item_type NOT NULL,
    rarity public.rarity_tier DEFAULT 'common'::public.rarity_tier NOT NULL,
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
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: player_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.player_stats (
    user_id uuid NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    experience integer DEFAULT 0 NOT NULL,
    gold integer DEFAULT 0 NOT NULL,
    crystals integer DEFAULT 0 NOT NULL,
    health_points integer DEFAULT 100 NOT NULL,
    max_health_points integer DEFAULT 100 NOT NULL,
    credibility_score double precision DEFAULT 1.0 NOT NULL,
    moral double precision DEFAULT 1.0 NOT NULL,
    streak integer DEFAULT 0 NOT NULL,
    max_streak integer DEFAULT 0 NOT NULL,
    last_active_date timestamp with time zone,
    achievements jsonb DEFAULT '{}'::jsonb NOT NULL,
    total_quests_completed integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
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
    last_active_date timestamp with time zone,
    settings jsonb DEFAULT '{}'::jsonb,
    achievements jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: leaderboard_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.leaderboard_view WITH (security_barrier='true', security_invoker='false') AS
 SELECT ps.user_id,
    ps.level,
    ps.experience AS xp,
    ps.streak,
    COALESCE(u.display_name, u.username, 'Aventurier'::text) AS display_name
   FROM (public.player_stats ps
     JOIN public.users u ON ((u.id = ps.user_id)));

--
-- Name: VIEW leaderboard_view; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.leaderboard_view IS '
SECURITY DEFINER intentionnel — faux positif Supabase Security 
Advisor.

Justification du bypass RLS :
- Le leaderboard nécessite de voir TOUS les joueurs, pas juste 
  le current user
- Sans bypass RLS, chaque user ne verrait que sa propre ligne 
  (RLS player_stats_self_access + users_select_own)

Protections compensatoires :
- security_barrier = true (anti-injection via fonctions volatiles)
- GRANT SELECT limité au rôle authenticated (pas anon, pas public)
- Projection limitée aux 5 colonnes publiques : 
  user_id (UUID opaque), level, xp, streak, display_name
- Aucune donnée sensible exposée (gold, crystals, moral, 
  credibility_score, achievements, email restent privés via RLS)

Alternative INVOKER rejetée : passer en SECURITY INVOKER 
nécessiterait une policy SELECT USING (true) sur player_stats 
qui ouvrirait toutes les colonnes (y compris sensibles) aux 
requêtes directes authentifiées.

Vigilance future : toute nouvelle colonne ajoutée à 
player_stats ou users doit être vérifiée — si elle apparaît 
dans le SELECT de cette vue, elle devient publique.
';

--
-- Name: premium_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.premium_subscriptions (
    user_id uuid NOT NULL,
    is_premium boolean DEFAULT false NOT NULL,
    premium_until timestamp with time zone,
    stripe_customer_id text,
    stripe_subscription_id text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: quest_difficulty_audit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quest_difficulty_audit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    quest_id uuid NOT NULL,
    user_id uuid NOT NULL,
    old_difficulty integer NOT NULL,
    new_difficulty integer NOT NULL,
    xp_delta integer NOT NULL,
    gold_delta integer NOT NULL,
    reason text NOT NULL,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    migration_tag text
);

--
-- Name: TABLE quest_difficulty_audit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.quest_difficulty_audit IS 'Table d''audit admin uniquement. RLS activée intentionnellement sans policy utilisateur. Accès via service_role (bypass RLS Supabase natif) ou dashboard admin.';

--
-- Name: quests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    category text NOT NULL,
    difficulty integer NOT NULL,
    rarity public.rarity_tier DEFAULT 'common'::public.rarity_tier NOT NULL,
    frequency public.quest_frequency DEFAULT 'one_off'::public.quest_frequency NOT NULL,
    estimated_duration_minutes integer DEFAULT 0,
    xp_reward integer DEFAULT 0,
    gold_reward integer DEFAULT 0,
    validation_type public.validation_type DEFAULT 'manual'::public.validation_type NOT NULL,
    proof_data text,
    is_completed boolean DEFAULT false NOT NULL,
    status public.quest_status DEFAULT 'active'::public.quest_status NOT NULL,
    sub_quests text[] DEFAULT ARRAY[]::text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deadline timestamp with time zone,
    completed_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT difficulty_range CHECK (((difficulty >= 1) AND (difficulty <= 4)))
);

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type text NOT NULL,
    item_id uuid,
    quantity integer DEFAULT 1 NOT NULL,
    gold_amount integer DEFAULT 0 NOT NULL,
    crystals_amount integer DEFAULT 0 NOT NULL,
    description text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT transactions_type_check CHECK ((type = ANY (ARRAY['purchase'::text, 'sale'::text, 'reward'::text, 'quest_completion'::text, 'gift'::text])))
);

--
-- Name: user_equipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_equipment (
    user_id uuid NOT NULL,
    weapon_id uuid,
    armor_id uuid,
    helmet_id uuid,
    shield_id uuid,
    outfit_id uuid,
    aura_id uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

--
-- Name: user_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_inventory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    item_id uuid NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    is_equipped boolean DEFAULT false,
    acquired_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_inventory_quantity_check CHECK ((quantity > 0))
);

--
-- Name: ai_validation_credits ai_validation_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_validation_credits
    ADD CONSTRAINT ai_validation_credits_pkey PRIMARY KEY (user_id);

--
-- Name: companions companions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companions
    ADD CONSTRAINT companions_pkey PRIMARY KEY (id);

--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);

--
-- Name: player_stats player_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_stats
    ADD CONSTRAINT player_stats_pkey PRIMARY KEY (user_id);

--
-- Name: premium_subscriptions premium_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premium_subscriptions
    ADD CONSTRAINT premium_subscriptions_pkey PRIMARY KEY (user_id);

--
-- Name: quest_difficulty_audit quest_difficulty_audit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_difficulty_audit
    ADD CONSTRAINT quest_difficulty_audit_pkey PRIMARY KEY (id);

--
-- Name: quest_difficulty_audit quest_difficulty_audit_quest_id_migration_tag_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quest_difficulty_audit
    ADD CONSTRAINT quest_difficulty_audit_quest_id_migration_tag_key UNIQUE (quest_id, migration_tag);

--
-- Name: quests quests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quests
    ADD CONSTRAINT quests_pkey PRIMARY KEY (id);

--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);

--
-- Name: user_equipment user_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_pkey PRIMARY KEY (user_id);

--
-- Name: user_inventory user_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_inventory
    ADD CONSTRAINT user_inventory_pkey PRIMARY KEY (id);

--
-- Name: user_inventory user_inventory_user_id_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_inventory
    ADD CONSTRAINT user_inventory_user_id_item_id_key UNIQUE (user_id, item_id);

--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

--
-- Name: idx_companions_user_main; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_companions_user_main ON public.companions USING btree (user_id, is_main) WHERE (is_main = true);

--
-- Name: idx_items_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_items_type ON public.items USING btree (type);

--
-- Name: idx_quests_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_quests_user ON public.quests USING btree (user_id);

--
-- Name: idx_users_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_level ON public.users USING btree (level);

--
-- Name: player_stats_updated_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX player_stats_updated_at_idx ON public.player_stats USING btree (updated_at DESC);

--
-- Name: ai_validation_credits ai_validation_credits_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER ai_validation_credits_updated_at BEFORE UPDATE ON public.ai_validation_credits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: player_stats player_stats_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER player_stats_updated_at BEFORE UPDATE ON public.player_stats FOR EACH ROW EXECUTE FUNCTION public.update_player_stats_updated_at();

--
-- Name: premium_subscriptions premium_subscriptions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER premium_subscriptions_updated_at BEFORE UPDATE ON public.premium_subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: companions update_companions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_companions_updated_at BEFORE UPDATE ON public.companions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: user_equipment update_equipment_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON public.user_equipment FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: quests update_quests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_quests_updated_at BEFORE UPDATE ON public.quests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

--
-- Name: ai_validation_credits ai_validation_credits_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_validation_credits
    ADD CONSTRAINT ai_validation_credits_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: companions companions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companions
    ADD CONSTRAINT companions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: player_stats player_stats_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.player_stats
    ADD CONSTRAINT player_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: premium_subscriptions premium_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premium_subscriptions
    ADD CONSTRAINT premium_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: quests quests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quests
    ADD CONSTRAINT quests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: transactions transactions_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: transactions transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: user_equipment user_equipment_armor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_armor_id_fkey FOREIGN KEY (armor_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_equipment user_equipment_aura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_aura_id_fkey FOREIGN KEY (aura_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_equipment user_equipment_helmet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_helmet_id_fkey FOREIGN KEY (helmet_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_equipment user_equipment_outfit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_outfit_id_fkey FOREIGN KEY (outfit_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_equipment user_equipment_shield_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_shield_id_fkey FOREIGN KEY (shield_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_equipment user_equipment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: user_equipment user_equipment_weapon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_equipment
    ADD CONSTRAINT user_equipment_weapon_id_fkey FOREIGN KEY (weapon_id) REFERENCES public.items(id) ON DELETE SET NULL;

--
-- Name: user_inventory user_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_inventory
    ADD CONSTRAINT user_inventory_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;

--
-- Name: user_inventory user_inventory_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_inventory
    ADD CONSTRAINT user_inventory_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

--
-- Name: users users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

--
-- Name: ai_validation_credits ai_credits_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ai_credits_insert_own ON public.ai_validation_credits FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: ai_validation_credits ai_credits_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ai_credits_select_own ON public.ai_validation_credits FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: ai_validation_credits ai_credits_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ai_credits_update_own ON public.ai_validation_credits FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: ai_validation_credits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ai_validation_credits ENABLE ROW LEVEL SECURITY;

--
-- Name: quest_difficulty_audit audit_service_role_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_service_role_access ON public.quest_difficulty_audit TO service_role USING (true) WITH CHECK (true);

--
-- Name: companions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.companions ENABLE ROW LEVEL SECURITY;

--
-- Name: companions companions_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY companions_delete_own ON public.companions FOR DELETE TO authenticated USING ((auth.uid() = user_id));

--
-- Name: companions companions_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY companions_insert_own ON public.companions FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: companions companions_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY companions_select_own ON public.companions FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: companions companions_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY companions_update_own ON public.companions FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

--
-- Name: items items_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY items_public_read ON public.items FOR SELECT TO authenticated USING (true);

--
-- Name: player_stats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.player_stats ENABLE ROW LEVEL SECURITY;

--
-- Name: player_stats player_stats_self_access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY player_stats_self_access ON public.player_stats TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: premium_subscriptions premium_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY premium_select_own ON public.premium_subscriptions FOR SELECT TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));

--
-- Name: premium_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.premium_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: quest_difficulty_audit; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quest_difficulty_audit ENABLE ROW LEVEL SECURITY;

--
-- Name: quests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;

--
-- Name: quests quests_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quests_delete_own ON public.quests FOR DELETE TO authenticated USING ((auth.uid() = user_id));

--
-- Name: quests quests_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quests_insert_own ON public.quests FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: quests quests_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quests_select_own ON public.quests FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: quests quests_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quests_update_own ON public.quests FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: transactions transactions_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transactions_insert_own ON public.transactions FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: transactions transactions_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY transactions_select_own ON public.transactions FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: user_equipment; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_equipment ENABLE ROW LEVEL SECURITY;

--
-- Name: user_equipment user_equipment_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_equipment_delete_own ON public.user_equipment FOR DELETE TO authenticated USING ((auth.uid() = user_id));

--
-- Name: user_equipment user_equipment_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_equipment_insert_own ON public.user_equipment FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: user_equipment user_equipment_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_equipment_select_own ON public.user_equipment FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: user_equipment user_equipment_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_equipment_update_own ON public.user_equipment FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: user_inventory; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_inventory ENABLE ROW LEVEL SECURITY;

--
-- Name: user_inventory user_inventory_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_inventory_delete_own ON public.user_inventory FOR DELETE TO authenticated USING ((auth.uid() = user_id));

--
-- Name: user_inventory user_inventory_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_inventory_insert_own ON public.user_inventory FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

--
-- Name: user_inventory user_inventory_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_inventory_select_own ON public.user_inventory FOR SELECT TO authenticated USING ((auth.uid() = user_id));

--
-- Name: user_inventory user_inventory_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY user_inventory_update_own ON public.user_inventory FOR UPDATE TO authenticated USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: users users_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_delete_own ON public.users FOR DELETE TO authenticated USING ((auth.uid() = id));

--
-- Name: users users_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_insert_own ON public.users FOR INSERT TO authenticated WITH CHECK ((auth.uid() = id));

--
-- Name: users users_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_select_own ON public.users FOR SELECT TO authenticated USING ((auth.uid() = id));

--
-- Name: users users_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY users_update_own ON public.users FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;

--
-- Name: FUNCTION experience_for_level(level integer); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.experience_for_level(level integer) TO anon;
GRANT ALL ON FUNCTION public.experience_for_level(level integer) TO authenticated;
GRANT ALL ON FUNCTION public.experience_for_level(level integer) TO service_role;

--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;

--
-- Name: FUNCTION update_player_stats_updated_at(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_player_stats_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_player_stats_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_player_stats_updated_at() TO service_role;

--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;

--
-- Name: TABLE ai_validation_credits; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.ai_validation_credits TO anon;
GRANT ALL ON TABLE public.ai_validation_credits TO authenticated;
GRANT ALL ON TABLE public.ai_validation_credits TO service_role;

--
-- Name: TABLE companions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.companions TO anon;
GRANT ALL ON TABLE public.companions TO authenticated;
GRANT ALL ON TABLE public.companions TO service_role;

--
-- Name: TABLE items; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.items TO anon;
GRANT ALL ON TABLE public.items TO authenticated;
GRANT ALL ON TABLE public.items TO service_role;

--
-- Name: TABLE player_stats; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.player_stats TO anon;
GRANT ALL ON TABLE public.player_stats TO authenticated;
GRANT ALL ON TABLE public.player_stats TO service_role;

--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.users TO anon;
GRANT ALL ON TABLE public.users TO authenticated;
GRANT ALL ON TABLE public.users TO service_role;

--
-- Name: TABLE leaderboard_view; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.leaderboard_view TO anon;
GRANT ALL ON TABLE public.leaderboard_view TO authenticated;
GRANT ALL ON TABLE public.leaderboard_view TO service_role;

--
-- Name: TABLE premium_subscriptions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.premium_subscriptions TO anon;
GRANT ALL ON TABLE public.premium_subscriptions TO authenticated;
GRANT ALL ON TABLE public.premium_subscriptions TO service_role;

--
-- Name: TABLE quest_difficulty_audit; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.quest_difficulty_audit TO anon;
GRANT ALL ON TABLE public.quest_difficulty_audit TO authenticated;
GRANT ALL ON TABLE public.quest_difficulty_audit TO service_role;

--
-- Name: TABLE quests; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.quests TO anon;
GRANT ALL ON TABLE public.quests TO authenticated;
GRANT ALL ON TABLE public.quests TO service_role;

--
-- Name: TABLE transactions; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.transactions TO anon;
GRANT ALL ON TABLE public.transactions TO authenticated;
GRANT ALL ON TABLE public.transactions TO service_role;

--
-- Name: TABLE user_equipment; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.user_equipment TO anon;
GRANT ALL ON TABLE public.user_equipment TO authenticated;
GRANT ALL ON TABLE public.user_equipment TO service_role;

--
-- Name: TABLE user_inventory; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.user_inventory TO anon;
GRANT ALL ON TABLE public.user_inventory TO authenticated;
GRANT ALL ON TABLE public.user_inventory TO service_role;

--
-- PostgreSQL database dump complete
--

-- Profil créé à l'inscription (déclencheur sur auth.users, hors schéma public).
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
