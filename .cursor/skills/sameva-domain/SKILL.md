---
name: sameva-domain
description: Applique la logique métier Sameva (quêtes, récompenses, items, équipement, Hive, Supabase). Utiliser lors de l'implémentation ou modification de règles de jeu, de récompenses, d'inventaire, d'équipement, ou d'accès données.
---

# Domaine et données Sameva

## Récompenses de quêtes (QuestRewardsCalculator)

- **Base** : XP = 10 × difficulté, or = 25 × difficulté. Cristaux si difficulté > 3.
- **Ponctualité** : +25 % en avance, +10 % à l'heure, -20 % en retard.
- **Streak** : +10 % si streak ≥ 7 jours.

Services dans `domain/services/quest_rewards_calculator.dart`. Utiliser `QuestRewardsCalculator.calculateBaseRewards(difficulty)` et `calculateRewardsWithTiming(quest, completedAt, hasStreakBonus: ...)`.

## Progression joueur

- Seuil XP : `(100 × level × 1.5).round()`.
- HP max : `100 + (level - 1) × 10`.

## Invocation / gacha

`ItemFactory.rollGachaRarity` respecte les probabilités suivantes :
Mythic 0,1 %, Legendary 0,9 %, Epic 4 %, Rare 10 %, Uncommon 25 %, Common 60 %.

## Autres services métier

- **BonusMalusService** : modificateurs de quête
- **HealthRegenerationService** : récupération HP
- **ItemFactory** : création d'items avec niveaux de rareté

Entités dans `domain/entities/` : `Item`, `Equipment`. Modèles dans `data/models/` (ex. `QuestModel`).

## Persistance

- **Supabase** : auth, quêtes, profils utilisateur, équipement cloud. Config dans `config/supabase_config.dart`. Clés dans `.env` : `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Hive** : données locales. Boxes ouvertes dans `main.dart` : `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`.

Après modification d'un modèle avec `@HiveType` / `@HiveField`, exécuter : `dart run build_runner build`.

Les accès données passent par les repositories et ViewModels. Les pages n'accèdent pas directement à Supabase ni aux boxes Hive.

Pour une migration Supabase, commenter le SQL, respecter les policies RLS existantes, tester par `SELECT` avant tout `UPDATE`/`DELETE`, et utiliser `ON DELETE CASCADE` pour les foreign keys vers `auth.users`.

## Inventaire et équipement

- **InventoryViewModel** : 50 emplacements, stack d'items, chargement par userId si nécessaire.
- **EquipmentViewModel** : slots d'équipement, chargement par userId si nécessaire.

Les ViewModels lisent/écrivent Hive (et Supabase si sync). Les pages utilisent `context.read<InventoryViewModel>()` / `context.watch<EquipmentViewModel>()` sans accéder directement aux boxes.

## Conventions

- Logique de calcul → `domain/services/`
- Entités pures → `domain/entities/`
- Modèles sérialisation / DB → `data/models/`
- Accès réseau ou disque → `data/` (repositories, datasources)
