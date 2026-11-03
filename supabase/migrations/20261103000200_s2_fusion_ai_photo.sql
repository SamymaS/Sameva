-- Sprint 2 : le type de validation « ai » est fusionné dans « photo ».
-- Les deux désignaient la même chose (preuve photo jugée par l'Oracle) sous
-- deux noms, ce qui doublait les cas à tester et à expliquer au joueur.

-- La garde de mise à jour fige validation_type : on la suspend le temps de la
-- conversion (aucune autre colonne n'est touchée).
ALTER TABLE public.quests DISABLE TRIGGER quests_guard_update;
UPDATE public.quests SET validation_type = 'photo' WHERE validation_type = 'ai';
ALTER TABLE public.quests ENABLE TRIGGER quests_guard_update;

ALTER TABLE public.quests DROP CONSTRAINT IF EXISTS quests_validation_type_valid;
ALTER TABLE public.quests ADD CONSTRAINT quests_validation_type_valid
  CHECK (validation_type IN ('manual', 'photo', 'timer', 'geolocation'));
