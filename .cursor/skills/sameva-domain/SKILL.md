---
name: sameva-domain
description: Applique la logique métier Sameva (quêtes, récompenses, items, équipement, Hive, Supabase). Utiliser lors de l'implémentation ou modification de règles de jeu, de récompenses, d'inventaire, d'équipement, ou d'accès données.
---

# Domaine et données Sameva

## Récompenses de quêtes (QuestRewardsCalculator)

- **Base** : XP = 10 × difficulté, Or = 25 × difficulté. Cristaux = 1 si difficulté > 3.
- **Ponctualité** : +25 % en avance, +10 % à l'heure, -20 % en retard.
- **Streak** : +10 % si streak ≥ 7 jours.
- **Level-up** : seuil XP `(100 × level × 1.5).round()`, HP max `100 + (level - 1) × 10`.

Services dans `domain/services/quest_rewards_calculator.dart`. Utiliser `QuestRewardsCalculator.calculateBaseRewards(difficulty)` et `calculateRewardsWithTiming(quest, completedAt, hasStreakBonus: ...)`.

## Autres services métier

- **BonusMalusService** : modificateurs de quête
- **HealthRegenerationService** : récupération HP
- **ItemFactory** : création d'items avec niveaux de rareté
- **ClaudeQuestGeneratorService / ClaudeValidationAiService** : génération et validation IA via appels `http`
- **NotificationService** : rappels locaux avec `flutter_local_notifications` et `timezone`

## Gacha

`ItemFactory.rollGachaRarity()` respecte les probabilités suivantes :

- Mythic : 0,1 %
- Legendary : 0,9 %
- Epic : 4 %
- Rare : 10 %
- Uncommon : 25 %
- Common : 60 %

Entités dans `domain/entities/` : `Item`, `Equipment`. Modèles dans `data/models/` (ex. `QuestModel`).

## Persistance

- **Supabase** : auth, quêtes, profils utilisateur, équipement cloud. Config dans `config/supabase_config.dart`. Clés dans `.env` : `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Hive** : données locales. Boxes ouvertes dans `main.dart` : `quests`, `playerStats`, `settings`, `inventory`, `equipment`, `cats`.

Après modification d'un modèle avec `@HiveType` / `@HiveField`, exécuter : `dart run build_runner build`.

## Inventaire et équipement

- **InventoryViewModel** : 50 emplacements, stack d'items, chargement local.
- **EquipmentViewModel** : slots d'équipement, chargement local.

Les ViewModels lisent/écrivent Hive via les repositories ou boxes injectées (et Supabase si sync). Les pages utilisent `context.read<InventoryViewModel>()` / `context.watch<EquipmentViewModel>()` sans accéder directement aux boxes.

## Supabase

- Les opérations DB passent par les repositories, use cases ou ViewModels, jamais directement depuis l'UI.
- Les migrations SQL doivent respecter les policies RLS existantes.
- Les clés étrangères vers `auth.users` utilisent `ON DELETE CASCADE`.
- Avant un `UPDATE` ou `DELETE` manuel, tester la portée avec un `SELECT`.

## Conventions

- Logique de calcul → `domain/services/`
- Entités pures → `domain/entities/`
- Modèles sérialisation / DB → `data/models/`
- Accès réseau ou disque → `data/` (repositories, datasources)
