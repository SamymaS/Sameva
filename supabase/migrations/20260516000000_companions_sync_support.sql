-- Migration B1 : alignement table companions avec modele Dart
-- CatStats. Strategie ADD/DROP validee sur table vide.
-- Date : 2026-05-16
-- Etape B1 du plan persistance cats cross-device.

BEGIN;

-- Garde : refuser la migration si table non-vide (protection
-- rejeu future)
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO row_count FROM public.companions;
  IF row_count > 0 THEN
    RAISE EXCEPTION
      'Migration B1 refusee : la table companions contient % rows. '
      'Cette migration suppose une table vide (DROP COLUMN irreversible). '
      'Investiguer avant d''appliquer.', row_count;
  END IF;
END $$;

-- ADD : colonnes specifiques cat
ALTER TABLE public.companions
  ADD COLUMN IF NOT EXISTS race TEXT NOT NULL DEFAULT 'michi',
  ADD COLUMN IF NOT EXISTS rarity TEXT NOT NULL DEFAULT 'common',
  ADD COLUMN IF NOT EXISTS is_main BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS equipped_hat TEXT,
  ADD COLUMN IF NOT EXISTS equipped_outfit_cosmetic TEXT,
  ADD COLUMN IF NOT EXISTS equipped_pants TEXT,
  ADD COLUMN IF NOT EXISTS equipped_shoes TEXT,
  ADD COLUMN IF NOT EXISTS equipped_aura TEXT,
  ADD COLUMN IF NOT EXISTS equipped_accessory TEXT,
  ADD COLUMN IF NOT EXISTS equipped_title TEXT;

-- CHECK constraints
ALTER TABLE public.companions
  DROP CONSTRAINT IF EXISTS companions_race_check;
ALTER TABLE public.companions
  ADD CONSTRAINT companions_race_check
  CHECK (race IN ('michi','lune','braise','neige','cosmos','sakura'));

ALTER TABLE public.companions
  DROP CONSTRAINT IF EXISTS companions_rarity_check;
ALTER TABLE public.companions
  ADD CONSTRAINT companions_rarity_check
  CHECK (rarity IN ('common','uncommon','rare','veryRare','epic',
                    'legendary','mythic'));

-- DROP : colonnes RPG generiques non utilisees par modele Dart
ALTER TABLE public.companions
  DROP COLUMN IF EXISTS level,
  DROP COLUMN IF EXISTS experience,
  DROP COLUMN IF EXISTS health_points,
  DROP COLUMN IF EXISTS max_health_points,
  DROP COLUMN IF EXISTS description,
  DROP COLUMN IF EXISTS image_path,
  DROP COLUMN IF EXISTS equipped_outfit_id;

-- Index partiel pour requetes main companion par user
CREATE INDEX IF NOT EXISTS idx_companions_user_main
  ON public.companions(user_id, is_main)
  WHERE is_main = true;

COMMIT;