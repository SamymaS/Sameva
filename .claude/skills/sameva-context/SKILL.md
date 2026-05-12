---
name: sameva-context
description: Vue d'ensemble du projet Sameva. À consulter EN PREMIER avant toute autre skill. Décrit la mission produit, le périmètre MVP, les principes UX directeurs, et les acteurs (Mougi, MougiBot, joueur). Utiliser quand un agent débute une tâche, quand l'utilisateur pose une question générale sur le projet, ou pour cadrer une décision produit.
---

# Contexte projet Sameva

## Pitch en une phrase

Sameva est une application Flutter qui transforme les tâches du quotidien en **quêtes RPG**, validées par une **IA de vision** (MougiBot) qui analyse une photo-preuve, avec un système de récompenses (XP, or, cristaux, équipement, cosmétiques) et un compagnon chat (Mougi).

## Objectifs

- **Produit** : MVP publié sur stores après certification
- **Certification** : RNCP 39583 — Expert en Développement Logiciel Niveau 7, YNOV 2025-2026, client fictif VitaLab
- **Bloc 1 oral** : juin 2026 · **Bloc 2 dossier** : juillet · **Bloc 4 dossier** : août · **Bloc 3 oral** : septembre · **Jury final** : octobre

## Acteurs et entités

| Entité | Rôle | Implémentation |
|---|---|---|
| **Joueur** | Utilisateur final, niveau, XP, or, cristaux, HP, moral, streak | `PlayerProvider` (Hive) + Supabase Auth |
| **Mougi** | Compagnon visuel — chat-tasse, race au choix (Braise/Lune/etc.) | Asset graphique + `CatStats` |
| **MougiBot** | Esprit analytique de Mougi — agent IA qui valide les preuves | Edge Function `analyze-quest-proof` + Claude Haiku Vision |
| **Quête** | Tâche à accomplir, avec difficulté, catégorie, validation | `QuestProvider` (Supabase) |

⚠️ **Ne JAMAIS confondre Mougi (visuel) et MougiBot (IA)**. À l'utilisateur on parle de "Mougi" pour le compagnon et de "MougiBot" pour la validation.

## Périmètre MVP (verrouillé pour Bloc 1)

### 🟢 Visible dans l'app (dockbar 5 onglets)

1. **Accueil** (Sanctuaire) — Hub : Mougi + stats + quêtes du jour
2. **Quêtes** — Création, À faire / Terminées, validation
3. **Portail** — Sous-onglets : Invocation gacha / Boutique / Vendre
4. **Chat** — Compagnon Mougi (3 slots cosmétiques actifs : Chapeau, Tenue, Aura)
5. **Profil** — Identité, équipement RPG, accès Stock + Succès + Paramètres

### 🔴 Masqué via feature flags (`lib/config/feature_flags.dart`)

- Jeux / Mini-Jeux (`showMinigames = false`)
- Classement (`showLeaderboard = false`)
- Historique des quêtes manquées (`showHistory = false`)
- Boss hebdomadaire sur Accueil (`showWeeklyBoss = false`)
- Marché Premium en cristaux (`showMarketPremium = false`)
- 4 slots cosmétiques extra : Pantalon, Chaussures, Accessoire, Titre

Le code est conservé, prêt à réactiver post-MVP avec la collab artistique Noyuss.

## Principes UX directeurs

1. **L'utilisateur n'est JAMAIS bloqué.** Si MougiBot est indisponible ou score < 70, validation manuelle disponible avec récompenses à 50 %.
2. **Bienveillance > punition.** Le ton de Mougi/MougiBot encourage, ne sanctionne pas.
3. **Permissions optionnelles.** L'app fonctionne sans appareil photo, sans GPS, sans notifications.
4. **Mode dégradé propre.** Hors-ligne ou erreur réseau → fallback Mock + Hive, jamais d'écran rouge.

## Stack technique

| Couche | Techno |
|---|---|
| **Front** | Flutter / Dart, Provider + ChangeNotifier, MVVM |
| **Backend** | Supabase (PostgreSQL, Auth, Edge Functions Deno, RLS, Storage) |
| **Cache local** | Hive (boxes `quests`, `playerStats`, `inventory`, `equipment`) |
| **IA** | Claude Haiku 4.5 Vision via Edge Function (jamais d'appel direct) |
| **CI/CD** | GitHub Actions |
| **Typo** | MedievalSharp (titres), Press Start 2P (stats), Quicksand (corps) |

## Repo et environnement

- **GitHub** : `https://github.com/SamymaS/Sameva.git`
- **Path local** : `~/Documents/ProjetsFlutter/Sameva`
- **Branche** : `main`
- **NAS** : Terramaster F4-424 Pro — backups Git nocturnes + assets lourds

## Skills à consulter selon le sujet

| Sujet | Skill |
|---|---|
| Architecture, structure de code | `sameva-architecture` |
| Couleurs, polices, widgets | `sameva-design-system` |
| Quêtes, récompenses, items, Hive, Supabase logique | `sameva-domain` |
| Base de données, RLS, requêtes SQL | `sameva-supabase` |
| Edge Functions, déploiement backend | `sameva-edge-functions` |
| Validation IA, MougiBot, prompt | `sameva-ia-integration` |

## Identités à ne pas confondre

- **Mougi** = le chat (visuel, asset, personnalité bienveillante)
- **MougiBot** = l'IA de validation (Edge Function + Claude Haiku)
- **Samy** = le solo dev (utilisateur de Claude Code)
- **VitaLab** = client fictif pour le cadrage certification
- **Noyuss** = collaboratrice artistique (phase 2 post-MVP)
