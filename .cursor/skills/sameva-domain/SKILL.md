---
name: sameva-domain
description: Applique la logique métier Sameva (quêtes, récompenses, items, équipement, Hive, Supabase). Utiliser lors de l'implémentation ou modification de règles de jeu, de récompenses, d'inventaire, d'équipement, ou d'accès données.
---

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
- **Hive** : données locales. Boxes ouvertes dans `main.dart` : `quests`, `playerStats`, `inventory`, `equipment`.

Après modification d'un modèle avec `@HiveType` / `@HiveField`, exécuter : `dart run build_runner build`.

## Inventaire et équipement

- **InventoryProvider** : 50 emplacements, stack d'items, chargement par userId.
- **EquipmentProvider** : slots d'équipement, chargement par userId.

Les providers lisent/écrivent Hive (et Supabase si sync). Les pages utilisent `context.read<InventoryProvider>()` / `context.watch<EquipmentProvider>()` sans accéder directement aux boxes.

## Conventions

- Logique de calcul → `domain/services/`
- Entités pures → `domain/entities/`
- Modèles sérialisation / DB → `data/models/`
- Accès réseau ou disque → `data/` (repositories, datasources)
