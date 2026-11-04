-- Réglages propres au banc d'essai : les tests de bout en bout ne peuvent pas
-- attendre 10 minutes qu'une quête déclarative soit validable.
UPDATE public.game_config SET value = '0' WHERE key = 'quest.min_age_minutes_declaratif';
UPDATE public.game_config SET value = '1000' WHERE key = 'quest.max_created_per_day';
