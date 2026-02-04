# Sameva — Vision recentrée (Reboot MVP)

## 1. Principe fondateur

**Sameva pousse l'utilisateur à réaliser des actions réelles** en rendant la validation des tâches **crédible, vérifiable et gratifiante**.

Tout le reste (avatar, loot, animations, IA, etc.) existe **uniquement** pour servir cette fonction.

- Si une fonctionnalité ne renforce pas la **création de quêtes**, leur **réalisation réelle** ou leur **validation fiable** → elle est exclue du MVP.

## 2. Cœur : la Quête

Une quête = **action réelle concrète, mesurable et vérifiable**.

Exemples : ranger une pièce, faire du sport, étudier 30 min, se rendre à un rendez-vous, effectuer une tâche planifiée.

La valeur de Sameva repose sur la **crédibilité de la validation**, pas sur le nombre de fonctionnalités.

## 3. Validation de quête (axe prioritaire n°1)

Objectif : **réduire la triche** sans rendre l’expérience lourde.

| Type | Description |
|------|-------------|
| **1. Validation simple** (fallback) | Checkbox manuelle, récompense réduite. Pour quêtes simples. |
| **2. Preuve visuelle** (prioritaire) | Photo ou courte vidéo prise dans l’app. Stockée temporairement, supprimée après analyse. |
| **3. IA** (différenciante) | L’IA reçoit titre, catégorie, preuve visuelle → renvoie score 0–100 + justification. Seuil : **70/100**. |

L’IA est un **outil d’aide à la décision** : analyser image/vidéo, comparer au contexte de la quête, produire un score explicable.

## 4. Pages strictement nécessaires (MVP — 6 pages)

| # | Page | Objectif |
|---|------|----------|
| 1 | **Authentification** | Connexion / inscription. Accès rapide au cœur. |
| 2 | **Mes Quêtes** | Liste des quêtes actives. À faire / en cours / terminée. Accès direct : créer une quête, valider une quête. |
| 3 | **Création de Quête** | Titre, catégorie, type de validation (simple / preuve visuelle), option durée / planification. Rapide à remplir. |
| 4 | **Validation de Quête** | Prendre photo/vidéo, indications (angle, zone), consentement, envoi vers analyse IA. Affichage score + explication → Validée / Refusée / Partielle. |
| 5 | **Récompense / Progression** | XP gagnée, points, déblocage simple (cosmétique ou badge). Feedback visuel léger. |
| 6 | **Profil / Historique** | Historique des quêtes validées, scores moyens, régularité, statistiques simples. |

## 5. Exclu du MVP (pour l’instant)

- Boutique, gacha avancé, mini-jeux, classements globaux, social, économie complexe, narration, décors évolutifs.

À réintroduire **seulement si** la validation de quêtes fonctionne et les utilisateurs jouent le jeu.

## 6. Implémentation actuelle (alignement)

- **App** (`app_new.dart`) : 2 onglets — **Mes Quêtes** (principal), **Profil**. FAB « Créer une quête ». Routes : `/create-quest`, `/quest/validate`, `/rewards`, `/profile`, `/settings`.
- **Validation** : `QuestValidationPage` — selon le type de quête, validation simple (checkbox) ou preuve visuelle (photo → analyse IA mock → score 0–100, seuil 70).
- **Service IA** : `ValidationAIService` (mock `MockValidationAIService`) — prêt pour branchement API réelle.
- **Modèle** : `Quest` avec `ValidationType` (manual, photo, timer, geolocation) et `proofData`.

## 7. Pourquoi ce reboot est pertinent (RNCP)

- Identifier une **fonctionnalité cœur**.
- Éliminer le **superflu**.
- Prioriser la **valeur réelle** (validation crédible).
- Traiter un **vrai problème** (triche).
- Intégrer l’**IA** de façon ciblée (analyse de preuve).
- Concevoir une app **réaliste** et livrable seul.
