---
name: sameva-domain
description: Applique la logique métier Sameva (quêtes, récompenses, items, équipement, Hive, Supabase). Utiliser lors de l'implémentation ou modification de règles de jeu, de récompenses, d'inventaire, d'équipement, ou d'accès données.
---

> **Mise à jour Sprint 1 (2026-10-21, ADR 0005) : prioritaire sur tout ce qui suit.**
> Les récompenses, l'XP, l'or, les cristaux, les Sceaux, la flamme, les PV et le gacha sont calculés
> **par le serveur** (`private.complete_quest`, `claim_daily`, `invoke`). Le client ne fait plus jamais
> `addGold`, `addExperience`, `addCrystals` ni aucun calcul via `QuestRewardsCalculator` : il appelle
> `GameApi` puis affiche la réponse. Les valeurs d'équilibrage sont dans la table `game_config`.
> Les sections ci-dessous décrivant un calcul côté client sont historiques.


# Domaine et données Sameva

## Récompenses de quêtes (QuestRewardsCalculator)

- **Base** : XP = 10 × difficulté, Or = 25 × difficulté. Cristaux = 1 si difficulté > 3.
- **Ponctualité** : +25 % en avance, +10 % à l'heure, -20 % en retard.
- **Streak** : +10 % si streak ≥ 7 jours.

Services dans `domain/services/quest_rewards_calculator.dart`. Utiliser `QuestRewardsCalculator.calculateBaseRewards(difficulty)` et `calculateRewardsWithTiming(quest, completedAt, hasStreakBonus: ...)`.

## Autres services métier

- **BonusMalusService** : modificateurs de quête
- **HealthRegenerationService** : récupération HP
- **ItemFactory** : création d'items avec niveaux de rareté

Entités dans `domain/entities/` : `Item`, `Equipment`. Modèles dans `data/models/` (ex. `QuestModel`).

## Persistance

- **Supabase** : auth, quêtes, profils utilisateur, équipement cloud. Config dans `config/supabase_config.dart`. Clés dans `.env` : `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Hive** : données locales. Boxes ouvertes dans `main.dart` : `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`, `aiValidation`. Boxes non typées + sérialisation JSON (`toJson`/`fromJson`), aucun TypeAdapter ni `build_runner`. **Pour le pattern complet (clés par utilisateur, lecture/écriture, offline-first, source de vérité), voir la skill `sameva-hive`.**

## Inventaire et équipement

- **InventoryProvider** : 50 emplacements, stack d'items, chargement par userId.
- **EquipmentProvider** : slots d'équipement, chargement par userId.

Les providers lisent/écrivent Hive (et Supabase si sync). Les pages utilisent `context.read<InventoryProvider>()` / `context.watch<EquipmentProvider>()` sans accéder directement aux boxes.

## Conventions

- Logique de calcul → `domain/services/`
- Entités pures → `domain/entities/`
- Modèles sérialisation / DB → `data/models/`
- Accès réseau ou disque → `data/` (repositories, datasources)
