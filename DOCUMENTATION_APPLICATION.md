# Documentation Complète - Sameva

## 📱 Vue d'ensemble

Sameva est une application mobile Flutter de gestion de tâches gamifiée, conçue pour transformer l'organisation du quotidien en une expérience ludique et motivante. L'application combine la productivité avec des éléments de jeu de rôle (RPG) pour encourager les utilisateurs à accomplir leurs objectifs quotidiens.

### Concept Principal

L'utilisateur crée des "quêtes" (tâches) qu'il doit accomplir dans sa vie quotidienne. Chaque quête complétée rapporte de l'expérience, de l'or, et potentiellement des items. Le système de gamification inclut :
- **Niveaux et progression** : Gagnez de l'XP pour monter en niveau
- **Points de vie (PV)** : Votre personnage a des PV qui peuvent diminuer si vous manquez des quêtes
- **Inventaire et équipement** : Collectez et équipez des items pour améliorer votre personnage
- **Mini-jeux** : Détendez-vous avec des jeux amusants
- **Personnalisation** : Customisez votre avatar avec des tenues, auras et compagnons

---

## 🎯 Architecture de l'Application

### Structure des Pages

L'application est organisée en plusieurs sections principales :

1. **Authentification** (`lib/pages/auth/`)
   - Connexion
   - Inscription
   - Onboarding

2. **Pages Principales** (`lib/pages/`)
   - Accueil
   - Marché
   - Invocation
   - Avatar/Personnalisation
   - Mini-jeux

3. **Gestion des Quêtes** (`lib/pages/quest/`)
   - Liste des quêtes
   - Création de quête
   - Détails de quête

4. **Profil et Paramètres** (`lib/pages/profile/`, `lib/pages/settings/`)
   - Profil utilisateur
   - Paramètres de l'application

5. **Inventaire** (`lib/pages/inventory/`)
   - Gestion des items
   - Équipement

### Navigation

L'application utilise une **barre de navigation inférieure** avec 5 onglets principaux :
1. 🏠 Accueil
2. 🛒 Marché
3. ✨ Invocation
4. 👤 Avatar
5. 🎮 Mini-Jeux

Des **routes nommées** permettent d'accéder aux pages secondaires :
- `/profile` - Profil utilisateur
- `/settings` - Paramètres
- `/quests` - Liste des quêtes
- `/inventory` - Inventaire
- `/ui-showcase` - Showcase des composants UI (développement)

---

## 🎨 Design System

### Palette de Couleurs

L'application utilise une palette de couleurs fantasy/médiévale :

**Couleurs Principales :**
- **Primary** : `#785096` (Violet)
- **Secondary** : `#DCD2EB` (Violet clair)
- **Accent** : `#C8B4DC` (Violet moyen)
- **Background** : `#F5F0F5` (Beige clair) / `#2A2438` (Violet foncé pour thème sombre)

**Couleurs de Rareté :**
- **Commun** : `#9E9E9E` (Gris)
- **Peu Commun** : `#4CAF50` (Vert)
- **Rare** : `#2196F3` (Bleu)
- **Très Rare** : `#9C27B0` (Violet)
- **Épique** : `#FF9800` (Orange)
- **Légendaire** : `#FFD700` (Or)
- **Mythique** : `#FF1744` (Rouge)

### Typographie

- **Police principale** : Poppins (via Google Fonts)
- **Police fantasy** : MedievalSharp (pour titres spéciaux)
- **Police rétro** : Press Start 2P (pour éléments gamifiés)

### Composants UI

L'application utilise des composants personnalisés inspirés de Figma :
- `FantasyCard` - Cartes avec bordures et ombres
- `FantasyButton` - Boutons avec effets de glow
- `FantasyBadge` - Badges de statut et rareté
- `FantasyAvatar` - Avatars avec images
- `FantasyBanner` - Bannières promotionnelles
- `FantasyTitle` - Titres stylisés

---

## 🔐 Système d'Authentification

### Pages d'Authentification

1. **Page de Connexion** (`lib/pages/auth/login_page.dart`)
   - Connexion par email/mot de passe
   - Mode test avec bypass pour développement
   - Navigation vers l'inscription

2. **Page d'Inscription** (`lib/pages/auth/register_page.dart`)
   - Création de compte
   - Validation des champs
   - Intégration Firebase Auth

3. **Page d'Onboarding** (`lib/pages/onboarding/onboarding_page.dart`)
   - Introduction à l'application
   - Présentation des fonctionnalités principales
   - Apparaît lors de la première utilisation

4. **Écran de Chargement** (`lib/pages/loading_screen.dart`)
   - Affichage pendant l'initialisation
   - Vérification de l'état d'authentification

5. **Splash Screen** (`lib/pages/splash/splash_screen.dart`)
   - Écran de démarrage avec logo
   - Animation d'introduction

---

## 📊 Système de Données

### Providers (State Management)

L'application utilise **Provider** pour la gestion d'état :

1. **AuthProvider** - Authentification utilisateur
2. **PlayerProvider** - Statistiques du joueur (niveau, XP, or, PV, etc.)
3. **QuestProvider** - Gestion des quêtes
4. **InventoryProvider** - Gestion de l'inventaire
5. **EquipmentProvider** - Gestion de l'équipement
6. **ThemeProvider** - Gestion du thème (clair/sombre)

### Stockage Local

- **Hive** - Base de données locale pour :
  - Inventaire
  - Équipement
  - Statistiques du joueur
  - Préférences utilisateur

### Backend

- **Firebase** :
  - Firebase Auth (authentification)
  - Cloud Firestore (quêtes, données utilisateur)

---

## 🎮 Systèmes de Gameplay

### 1. Système d'Expérience et Niveaux
- Gain d'XP via quêtes complétées
- Formule : `XP requis = 100 × (niveau × 1.5)`
- +10 PV max par niveau

### 2. Système de Points de Vie (PV)
- 100 PV de base au niveau 1
- Régénération automatique (1% par heure)
- Perte de PV si quêtes manquées
- Mort si PV = 0 (réinitialisation)

### 3. Système de Bonus/Malus
- Bonus pour complétion à temps
- Bonus de streak (jours consécutifs)
- Malus pour quêtes manquées
- Malus d'inactivité

### 4. Système d'Inventaire
- 50 slots maximum
- Items empilables (consommables)
- Organisation par type

### 5. Système d'Équipement
- 6 slots : Arme, Armure, Casque, Bouclier, Tenue, Aura
- Bonus de stats selon l'équipement
- Affichage visuel sur l'avatar

---

## 📱 Pages Principales

### 1. Page d'Accueil (`lib/pages/home/new_home_page.dart`)
- Vue d'ensemble des quêtes du jour
- Statistiques du joueur
- Accès rapide aux fonctionnalités
- Bouton de création de quête

### 2. Page Marché (`lib/pages/market/market_page.dart`)
- Achat d'items avec or
- Affichage des items disponibles
- Filtres par type et rareté
- Vérification de l'or disponible

### 3. Page Invocation (`lib/pages/invocation/invocation_page.dart`)
- 3 types d'invocations (gratuit, or, premium)
- Probabilités selon la rareté
- Animation d'invocation
- Ajout automatique à l'inventaire

### 4. Page Avatar (`lib/pages/avatar/avatar_page.dart`)
- Personnalisation de l'avatar
- Équipement de tenues, auras, armes, boucliers
- Compagnons
- Preview en temps réel

### 5. Page Mini-Jeux (`lib/pages/minigame/minigame_page.dart`)
- 6 mini-jeux disponibles
- Navigation vers chaque jeu
- Système de verrouillage/déverrouillage

---

## 📝 Documentation Détaillée

Pour plus de détails sur chaque section, consultez :

1. **[DOCUMENTATION_AUTHENTIFICATION.md](./DOCUMENTATION_AUTHENTIFICATION.md)** - Pages d'auth et onboarding
2. **[DOCUMENTATION_PAGES_PRINCIPALES.md](./DOCUMENTATION_PAGES_PRINCIPALES.md)** - Pages principales et navigation
3. **[DOCUMENTATION_QUETES.md](./DOCUMENTATION_QUETES.md)** - Système de quêtes complet
4. **[DOCUMENTATION_MINI_JEUX.md](./DOCUMENTATION_MINI_JEUX.md)** - Tous les mini-jeux
5. **[DOCUMENTATION_PERSONNALISATION.md](./DOCUMENTATION_PERSONNALISATION.md)** - Avatar, inventaire, équipement
6. **[DOCUMENTATION_MARCHE_INVOCATION.md](./DOCUMENTATION_MARCHE_INVOCATION.md)** - Marché et invocations
7. **[DOCUMENTATION_DESIGN_SYSTEM.md](./DOCUMENTATION_DESIGN_SYSTEM.md)** - Design system et composants UI
8. **[DOCUMENTATION_NAVIGATION.md](./DOCUMENTATION_NAVIGATION.md)** - Routes et navigation
9. **[DOCUMENTATION_FONCTIONNALITES.md](./DOCUMENTATION_FONCTIONNALITES.md)** - Fonctionnalités système

---

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK
- Firebase configuré
- Hive initialisé

### Installation
```bash
flutter pub get
flutter run
```

### Structure des Assets
- `assets/images/` - Images (avatars, items, backgrounds)
- `assets/animations/` - Animations Lottie/Rive
- `assets/audio/` - Musique et effets sonores
- `assets/minigames/` - Assets pour mini-jeux
- `assets/icons/` - Icônes et items

---

## 📄 Licence

Propriétaire - Tous droits réservés

