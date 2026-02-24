-- Migration P1.3 : table player_stats pour synchroniser les stats joueur entre appareils.
-- Les stats (niveau, XP, or...) étaient uniquement locales (Hive), elles sont désormais
-- persistées sur Supabase et chargées au démarrage de session.

CREATE TABLE IF NOT EXISTS player_stats (
  user_id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  level            INT     NOT NULL DEFAULT 1,
  experience       INT     NOT NULL DEFAULT 0,
  gold             INT     NOT NULL DEFAULT 0,
  crystals         INT     NOT NULL DEFAULT 0,
  health_points    INT     NOT NULL DEFAULT 100,
  max_health_points INT    NOT NULL DEFAULT 100,
  credibility_score FLOAT  NOT NULL DEFAULT 1.0,
  moral            FLOAT   NOT NULL DEFAULT 1.0,
  streak           INT     NOT NULL DEFAULT 0,
  max_streak       INT     NOT NULL DEFAULT 0,
  last_active_date TIMESTAMPTZ,
  achievements     JSONB   NOT NULL DEFAULT '{}',
  total_quests_completed INT NOT NULL DEFAULT 0,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security : chaque utilisateur ne peut accéder qu'à ses propres stats
ALTER TABLE player_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "player_stats_self_access" ON player_stats
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS player_stats_updated_at_idx ON player_stats(updated_at DESC);

-- Trigger pour updated_at automatique
CREATE OR REPLACE FUNCTION update_player_stats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER player_stats_updated_at
  BEFORE UPDATE ON player_stats
  FOR EACH ROW EXECUTE FUNCTION update_player_stats_updated_at();
