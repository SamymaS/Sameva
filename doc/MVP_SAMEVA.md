# Guide Développeur – MVP Sameva

> **Version :** 2.0 – Révisée et recentrée
> **Dernière mise à jour :** 12 février 2026
> **Statut :** En cours de développement

---

## 1. Introduction

### 1.1 Qu'est-ce que Sameva ?

Sameva est une application mobile qui transforme les actions du quotidien (étudier, faire du sport, prendre soin de soi, avancer sur un objectif) en une aventure RPG où chaque effort a un impact visible.

L'utilisateur évolue dans un univers fantasy doux et lumineux. Son avatar reflète sa progression réelle. Les tâches deviennent des quêtes, les récompenses prennent la forme d'objets, d'XP et de personnalisation.

**Sameva n'est pas un jeu, mais une expérience gamifiée du quotidien, centrée sur la motivation, l'estime de soi et la constance.**

### 1.2 Les problèmes que Sameva résout

Les outils de productivité classiques (todo-lists, agendas, trackers) souffrent du même défaut : leur froideur. Ils sont efficaces mais rarement engageants.

Sameva cherche à résoudre trois problèmes essentiels :

- **L'absence de récompense émotionnelle** lorsque l'on progresse dans la vie réelle
- **Le manque de suivi visuel** qui rend les efforts invisibles
- **La difficulté à rester motivé sur le long terme** faute d'un système narratif ou symbolique

### 1.3 Notre solution

Chaque tâche accomplie dans la vraie vie nourrit un avatar et un univers visuel. L'utilisateur est récompensé proportionnellement à ses efforts réels : XP, objets, personnalisation, niveaux.

---

## 2. Objectif du MVP

Le MVP a une ambition claire : **permettre aux premiers utilisateurs de vivre la boucle d'expérience centrale de Sameva.**

### La boucle essentielle (Core Loop)

```
Créer une quête → Accomplir la quête → Recevoir une récompense → Voir son avatar évoluer
```

Le MVP doit être **simple, fluide et suffisant** pour que les utilisateurs comprennent immédiatement la valeur du concept. Il ne vise pas la profondeur d'un jeu complet.

### Ce que le MVP inclut (Phase 1)

| Fonctionnalité | Priorité | Description |
|---|---|---|
| Authentification | 🔴 Critique | Inscription / Connexion (email + mot de passe) |
| Création de quêtes | 🔴 Critique | Interface pour créer une tâche réelle comme quête |
| Liste des quêtes | 🔴 Critique | Voir ses quêtes en cours / accomplies |
| Validation de quête | 🔴 Critique | Marquer une quête comme terminée |
| Système de récompenses | 🔴 Critique | Gagner XP + pièces à chaque quête validée |
| Avatar basique | 🔴 Critique | Affichage d'un avatar qui évolue avec le niveau |
| Inventaire simple | 🟡 Important | Voir les objets obtenus en récompense |
| Personnalisation basique | 🟡 Important | Équiper des objets sur son avatar |
| Page Profil | 🟡 Important | Voir son niveau, XP, statistiques |

### Ce que le MVP N'inclut PAS (Phase 2+)

| Fonctionnalité | Raison du report |
|---|---|
| Sanctuaire immersif (décor interactif) | Nécessite des assets lourds non disponibles |
| Boutique / Marché quotidien | Complexité économique prématurée |
| Système d'invocation (gacha) | Feature avancée, pas essentielle à la boucle |
| Mini-jeux | Hors scope de la boucle centrale |
| Compagnon spirituel (familier) | Nécessite assets + mécanique dédiée |
| Back-office admin | Pas nécessaire sans base utilisateurs |
| DA sonore | Post-MVP |
| Système d'auras avancé | Post-MVP |

---

## 3. Contraintes techniques

### 3.1 Stack technologique

| Couche | Technologie | Rôle |
|---|---|---|
| Frontend | Flutter + Dart | Application mobile cross-platform |
| Backend | Supabase | Auth, base de données (PostgreSQL), stockage |
| Animations | Lottie | Micro-animations UI (récompenses, transitions) |
| State Management | Riverpod (ou Bloc) | Gestion d'état côté Flutter |

> **Note :** Rive et Flame sont envisagés pour les phases futures (animations avatar avancées, mini-jeux) mais ne sont **pas requis** pour le MVP.

### 3.2 Performance (objectifs réalistes)

- Application fonctionnelle et stable sur iOS et Android
- Transitions fluides entre les pages
- Temps de chargement raisonnables (< 3s au lancement)
- Optimisation progressive, pas de blocage sur la perfection

### 3.3 Sécurité

- Authentification via Supabase Auth (token + refresh)
- Communication HTTPS obligatoire
- Validation côté serveur pour les récompenses (anti-triche basique)
- Row Level Security (RLS) sur Supabase

### 3.4 Compatibilité

- iOS 14+
- Android 10+
- Testé sur smartphones récents

---

## 4. Architecture

### 4.1 Vision d'ensemble

Pour le MVP, on garde une architecture **simple et monolithique** via Supabase. Pas de micro-services, pas de complexité inutile.

```
┌─────────────────────────┐
│     App Flutter          │
│  (UI + State + Logic)    │
└──────────┬──────────────┘
           │ REST API
┌──────────▼──────────────┐
│       Supabase           │
│  ┌─────────────────────┐ │
│  │ Auth                 │ │
│  │ PostgreSQL (DB)      │ │
│  │ Storage (assets)     │ │
│  │ Edge Functions       │ │
│  └─────────────────────┘ │
└──────────────────────────┘
```

### 4.2 Tables principales (Supabase)

| Table | Description |
|---|---|
| `users` | Profil utilisateur (pseudo, niveau, XP, pièces) |
| `quests` | Quêtes créées (titre, description, catégorie, statut, récompense) |
| `inventory` | Objets possédés par l'utilisateur |
| `items` | Catalogue des objets disponibles (nom, rareté, type, image) |
| `avatar_equipment` | Objets actuellement équipés sur l'avatar |
| `quest_rewards` | Historique des récompenses reçues |

### 4.3 Logique métier clé

**Validation d'une quête :**
```
Quête validée → Calcul récompense (XP + pièces + item aléatoire possible)
             → Mise à jour profil utilisateur (XP, niveau)
             → Ajout item à l'inventaire (si drop)
             → Notification visuelle de récompense
```

**Calcul de niveau :**
```
Niveau = f(XP total)
Seuils progressifs : 100, 250, 500, 800, 1200...
Chaque quête donne entre 10 et 50 XP selon la difficulté
```

---

## 5. Pages de l'application (MVP)

### 5.1 Pages à développer

| # | Page | Description |
|---|---|---|
| 1 | **Onboarding** | 2-3 écrans d'introduction + création de compte |
| 2 | **Accueil / Hub** | Vue principale avec avatar, niveau, XP, accès rapide aux quêtes |
| 3 | **Création de quête** | Formulaire : titre, description, catégorie, difficulté |
| 4 | **Liste des quêtes** | Quêtes actives, terminées, avec filtres simples |
| 5 | **Validation de quête** | Écran de confirmation + animation de récompense |
| 6 | **Inventaire** | Grille d'objets possédés avec détails |
| 7 | **Personnalisation avatar** | Équiper / retirer des objets cosmétiques |
| 8 | **Profil** | Statistiques, niveau, historique |
| 9 | **Paramètres** | Compte, notifications, déconnexion |

### 5.2 Navigation

```
Hub (Accueil)
├── Quêtes (créer / liste / valider)
├── Inventaire
├── Personnalisation Avatar
├── Profil
└── Paramètres
```

> Navigation principale via une **bottom navigation bar** ou un **menu latéral** – à définir lors du design.

---

## 6. Direction Artistique (DA) – Référence

> **⚠️ Cette section sert de référence pour la vision long terme. Pour le MVP, l'implémentation visuelle sera adaptée aux assets disponibles.**

### 6.1 Ambiance cible

- Palette douce : bleus profonds, violets doux, nuances pastel
- Ambiance nocturne mais lumineuse, jamais sombre
- Effets lumineux subtils (halos, particules) → **implémentés progressivement**
- Transparence et dégradés doux

### 6.2 Style graphique cible

- Style illustratif 2D semi-peint
- Textures douces, contours discrets
- Ombres colorées (bleu/violet) plutôt que noires
- Lumière diffuse autour des éléments interactifs

### 6.3 Avatar – Principes

- Proportions stylisées, légèrement cartoon RPG
- Expressions neutres ou positives
- Silhouettes lisibles même en petit format
- **MVP : avatar simple avec système d'équipement par couches (layers)**

### 6.4 UI – Principes

- Icônes en outline doux, arrondies
- Boutons arrondis à dégradé doux
- Transitions animées légères (fade-in, scale)
- **MVP : UI propre et fonctionnelle, magie ajoutée progressivement**

### 6.5 Typographie

- Titres : serif élégante (style fantasy)
- Textes : sans-serif douce, arrondie, lisible
- Couleurs typographiques : crème, doré doux, bleu clair

### 6.6 Les 6 piliers visuels de Sameva

1. **Douceur** – Pas de couleurs agressives ni contrastes durs
2. **Magie** – Halos, particules, auras, lumières
3. **Sérénité** – Postures calmes, ambiance nocturne douce
4. **Mystique** – Symboles sacrés, runes, architecture antique
5. **Nature** – Feuillages, brume, pierres, environnement vivant
6. **Illustration soignée** – Peint main soft, contours légers

---

## 7. Cas d'utilisation (MVP)

### CU-01 : Inscription
- **Acteur :** Nouvel utilisateur
- **Objectif :** Créer un compte
- **Scénario :** Email + mot de passe → Création profil → Choix pseudo → Avatar par défaut → Accès au Hub

### CU-02 : Créer une quête
- **Acteur :** Utilisateur connecté
- **Objectif :** Transformer une tâche réelle en quête
- **Scénario :** Bouton "+" → Formulaire (titre, description, catégorie, difficulté) → Confirmation → Quête ajoutée à la liste

### CU-03 : Valider une quête
- **Acteur :** Utilisateur ayant une quête active
- **Objectif :** Marquer une tâche comme accomplie
- **Scénario :** Sélection quête → Bouton "Valider" → Animation de récompense → XP + pièces + item possible → Retour liste

### CU-04 : Consulter l'inventaire
- **Acteur :** Utilisateur connecté
- **Objectif :** Voir ses objets
- **Scénario :** Menu → Inventaire → Grille d'objets → Détail d'un objet (nom, rareté, description)

### CU-05 : Personnaliser son avatar
- **Acteur :** Utilisateur avec des objets
- **Objectif :** Équiper un objet cosmétique
- **Scénario :** Menu → Personnalisation → Sélection slot (tête, corps, accessoire) → Équiper → Aperçu en temps réel

### CU-06 : Consulter son profil
- **Acteur :** Utilisateur connecté
- **Objectif :** Voir sa progression
- **Scénario :** Menu → Profil → Niveau, XP, quêtes accomplies, statistiques

---

## 8. Système économique (MVP – simplifié)

| Élément | Détail |
|---|---|
| **XP** | Gagné à chaque quête validée (10-50 selon difficulté) |
| **Pièces (or)** | Monnaie de base, gagnée avec les quêtes (5-25 par quête) |
| **Items** | Drop aléatoire à la validation (probabilité ~20-30%) |
| **Raretés** | Commun (60%), Peu commun (25%), Rare (12%), Épique (3%) |
| **Niveaux** | Progression par paliers d'XP croissants |

> Le système économique sera ajusté après les premiers tests utilisateurs. Garder les choses simples au départ.

---

## 9. Planning MVP

| Phase | Durée estimée | Description |
|---|---|---|
| 1. Setup & Architecture | 1-2 semaines | Projet Flutter, Supabase, structure de base |
| 2. Auth & Profil | 1-2 semaines | Inscription, connexion, profil utilisateur |
| 3. Système de quêtes | 2-3 semaines | CRUD quêtes, validation, récompenses |
| 4. Avatar & Inventaire | 2-3 semaines | Affichage avatar, inventaire, équipement |
| 5. Personnalisation | 1-2 semaines | Système d'équipement cosmétique |
| 6. UI/UX & Polish | 2-3 semaines | Animations, transitions, cohérence visuelle |
| 7. Tests & Corrections | 1-2 semaines | Bugs, UX, performance |

**Durée totale estimée : 10-17 semaines**

---

## 10. Ressources et Outils

| Catégorie | Outil |
|---|---|
| Code | Flutter + Dart |
| Backend | Supabase |
| Versioning | GitHub |
| Design | Figma |
| IA | Claude, Cursor |
| Gestion de projet | Notion ou Trello |
| Communication | Discord |

---

## 11. Décisions ouvertes (à trancher)

- [ ] Choix du state management (Riverpod vs Bloc)
- [ ] Source des assets avatar (création manuelle ? IA ? pack acheté ?)
- [ ] Style exact de la bottom nav / navigation
- [ ] Mécaniques détaillées du drop d'items
- [ ] Catégories de quêtes disponibles
- [ ] Système de notifications (rappels de quêtes)

---

## 12. Vision future (Post-MVP)

Ces fonctionnalités sont la vision long terme de Sameva. Elles ne sont pas dans le MVP mais guident les choix d'architecture :

- **Sanctuaire immersif** – Décor interactif évolutif
- **Compagnon spirituel** – Familier qui accompagne l'utilisateur
- **Boutique quotidienne** – Rotation d'objets avec monnaie in-game
- **Système d'invocation (gacha)** – Tirage aléatoire d'objets rares
- **Mini-jeux** – Petits jeux pour gagner des bonus
- **Système d'auras** – Effets visuels liés à la progression
- **DA sonore** – Ambiance musicale et effets sonores
- **Social** – Amis, classements, défis entre joueurs
- **Back-office admin** – Dashboard de gestion
- **Animations Rive avancées** – Avatar et compagnon animés

---

*Ce document est vivant. Il sera mis à jour au fil du développement.*
