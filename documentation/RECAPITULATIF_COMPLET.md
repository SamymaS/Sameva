# Récapitulatif Complet de l'Application Sameva

## 📋 Introduction

Ce document présente le récapitulatif complet et structuré de l'application **Sameva**, basé sur le Game Design Document (GDD) technique et artistique du projet.

**Sameva** est une application de productivité gamifiée, inspirée des codes du RPG Fantasy, dans laquelle l'accomplissement de tâches réelles permet de faire progresser un avatar virtuel, un univers visuel et une progression personnelle.

L'objectif est de transformer la discipline, la constance et l'effort quotidien en une expérience motivante, gratifiante et émotionnellement engageante.

---

## 1. Vision et Concept Général

### 1.1 Principe Fondamental

Sameva repose sur un principe simple mais puissant :
👉 **Chaque action réelle a un impact visible dans l'univers de l'application.**

L'utilisateur ne "gère pas une liste de tâches", il évolue dans un monde, développe son avatar, débloque des objets, améliore son sanctuaire et construit une progression sur le long terme.

### 1.2 Positionnement

L'application se situe à l'intersection de :

- **La productivité personnelle** - Gestion efficace des tâches quotidiennes
- **La gamification** - Mécaniques de jeu appliquées à la vie réelle
- **Le jeu de rôle léger** - Progression d'avatar et développement de personnage
- **Le bien-être numérique** - Expérience positive et motivante

### 1.3 Valeur Proposée

- **Motivation intrinsèque** : La progression visuelle et tangible encourage la constance
- **Récompenses immédiates** : Chaque quête complétée apporte des récompenses visibles
- **Progression à long terme** : Développement d'un avatar et d'un univers personnel
- **Engagement émotionnel** : Attachement à l'avatar, au familier et à l'univers

---

## 2. Identité Visuelle et Système Artistique

### 2.1 Ambiance Générale

L'identité visuelle de Sameva est pensée comme un **univers magique, mystique et céleste**, avec une atmosphère apaisante mais valorisante.

#### Palette Dominante

- **Bleu nuit** - Profondeur et mystère
- **Violet profond** - Magie et spiritualité
- **Turquoise** - Énergie et vitalité
- **Or doux** - Récompense et valeur

#### Objectifs Visuels

- Créer un sentiment de **calme** et de **sérénité**
- Évoquer la **progression** et l'**évolution**
- Valoriser les **récompenses** sans surcharge visuelle
- Éviter l'**agressivité** et la surstimulation

### 2.2 Système de Rareté

La rareté est un élément central de la motivation et de la progression. Elle s'applique aux objets, équipements, cosmétiques et récompenses.

| Rareté | Couleur | Effets Visuels |
|--------|---------|----------------|
| **Commun** | Gris | Aucun effet particulier |
| **Peu Commun** | Vert | Légère brillance |
| **Rare** | Bleu | Lueur douce |
| **Épique** | Violet | Effet de glow (lueur) |
| **Légendaire** | Or | Particules lumineuses |
| **Mythique** | Rouge / Corail | Aura pulsante |

#### Impact du Système de Rareté

- **Renforce la valeur perçue** des récompenses
- **Crée un attachement progressif** à l'univers
- **Motive la collecte** et la progression
- **Différencie visuellement** les objets selon leur importance

### 2.3 Principes de Design

- **Glassmorphism** : Effets de verre dépoli pour les cartes et interfaces
- **Particules magiques** : Animations subtiles pour créer l'ambiance
- **Transitions fluides** : Mouvements doux entre les écrans
- **Hiérarchie visuelle** : Mise en avant des éléments importants

---

## 3. Pages Principales et Fonctionnalités

### 3.1 Accueil et Accès

#### Splash Screen

**Fonctionnalités :**
- Logo Sameva animé
- Fond céleste avec dégradé
- Particules magiques en mouvement
- Transition fluide vers l'onboarding

**Objectif :** Créer une première impression immersive et magique

#### Onboarding

**Structure :**
- Carrousel de 3 écrans
- Présentation du concept :
  - **Quêtes** - Système de tâches gamifiées
  - **Progression** - Développement de l'avatar
  - **Avatar & Familier** - Personnalisation et compagnon

**Objectif :** Expliquer rapidement les mécaniques principales

#### Authentification

**Options :**
- Connexion / Inscription par **Email**
- Connexion / Inscription par **Google**

**Design :**
- Carte centrale avec effet **glassmorphism**
- Interface légère et rassurante
- Transitions douces

---

### 3.2 Hub Principal — Le Sanctuaire

Le **Sanctuaire** est le cœur émotionnel et fonctionnel de l'application.

#### Fonctionnalités Principales

**Affichage Central :**
- **Avatar** affiché au centre (2D ou 2.5D) avec équipement visible
- **Familier** flottant à proximité de l'avatar
- **Barre d'XP** et niveau en haut de l'écran
- **Carrousel des quêtes du jour** en bas de l'écran

**Actions :**
- **Bouton d'action principal (FAB)** "+" pour créer une quête
- Navigation vers les autres sections

#### Évolution Visuelle

Le sanctuaire évolue visuellement en fonction de :
- Le niveau du joueur
- Les objets débloqués
- La progression globale
- Les succès obtenus

---

### 3.3 Gestion des Quêtes — Le Cœur du Jeu

#### Liste des Quêtes

**Affichage :**
- Quêtes sous forme de **cartes stylisées**
- **Filtres par catégorie** :
  - Travail
  - Sport
  - Maison
  - Personnel
  - Autres...

**Informations Visibles :**
- **Titre** de la quête
- **Récompenses** (XP / Or)
- **Checkbox runique** pour valider
- **Difficulté** (1 à 3 étoiles)
- **Catégorie** avec icône

#### Création de Quête — Le Grimoire

**Interface :**
- Formulaire stylisé **parchemin magique**
- Design immersif et thématique

**Options de Création :**
- **Choix de la difficulté** (1 à 3 étoiles)
  - Impact direct sur les récompenses
- **Sélection de catégorie** via icônes
- **Titre et description** personnalisés
- **Date d'échéance** (optionnelle)

**Récompenses Calculées :**
- Basées sur la difficulté
- Ajustées selon le timing (bonus/malus)
- Affichées avant validation

---

### 3.4 Progression et Personnalisation

#### Inventaire — Le Coffre Astral

**Affichage :**
- **Grille d'objets** organisée
- **Bordures colorées** selon la rareté
- **Filtres** par type d'objet

**Contenu :**
- **Équipements** (armes, tenues, accessoires)
- **Potions** (bonus temporaires)
- **Matériaux** (ressources de craft)
- **Cosmétiques** (apparences)

**Actions :**
- Consultation des détails
- Équipement direct
- Tri et organisation

#### Customisation — Le Miroir des Âmes

**Fonctionnalités :**
- Modification de l'apparence de l'avatar
- **Changements visibles en temps réel**

**Slots d'Équipement :**
- **Arme** - Impact sur les statistiques
- **Tenue** - Apparence et bonus
- **Aura** - Effet visuel autour de l'avatar
- **Familier** - Compagnon magique

**Personnalisation :**
- Choix parmi les objets débloqués
- Prévisualisation avant équipement
- Sauvegarde automatique

#### Profil — Le Hall des Héros

**Statistiques Globales :**
- **Jours de suite** (streak)
- **Total de quêtes accomplies**
- **Niveau actuel** et progression
- **Or et Cristaux** possédés

**Succès et Hauts-Faits :**
- Liste des accomplissements
- Badges et récompenses spéciales
- Historique des activités

**Historique :**
- Activités récentes
- Progression sur le temps
- Graphiques de performance

---

### 3.5 Économie et Divertissement

#### Boutique — Le Marché Astral

**Fonctionnalités :**
- Achat d'objets et cosmétiques
- **Utilisation de l'Or** (monnaie principale)
- **Utilisation de Cristaux** (monnaie premium)

**Caractéristiques :**
- **Timer de rafraîchissement** des objets disponibles
- Rotation quotidienne des objets
- Offres spéciales limitées
- Catégories d'objets (équipements, cosmétiques, potions)

**Affichage :**
- Grille d'objets avec prix
- Prévisualisation des objets
- Indication de rareté

#### Invocation / Gacha — Le Portail

**Mécanique :**
- **Tirage aléatoire** d'objets ou d'équipements
- Animation de **vortex magique**
- Système de probabilités selon la rareté

**Types d'Invocations :**
- **Invocation gratuite quotidienne** (1 par jour)
- **Invocation premium** (coûte des Cristaux)
- **Invocation spéciale** (événements)

**Écran de Récompense :**
- **Mise en scène épique** du loot obtenu
- **Rayons de lumière** et effets visuels
- **Vibrations** et effets sonores
- **Accent sur la valeur** de la récompense

#### Mini-Jeux

**Mini-Jeu Principal : Harmonie Astrale**

- **Type** : Jeu de rythme / tracé de runes
- **Gain** : Bonus temporaires pour les quêtes
- **Menu de sélection** : Type Cover Flow

**Autres Mini-Jeux Disponibles :**
- **Match-3** - Puzzle de correspondance
- **Memory Quest** - Jeu de mémoire
- **Platformer** - Jeu de plateforme
- **Puzzle Quest** - Puzzle logique
- **Runner** - Course infinie
- **Speed Challenge** - Défi de vitesse

**Récompenses :**
- Bonus temporaires pour les quêtes
- Or et XP
- Items rares (occasionnellement)

---

### 3.6 Social et Réglages

#### Social

**Fonctionnalités :**
- **Liste d'amis** - Gestion des connexions
- **Consultation de profils** - Voir la progression des autres
- **Envoi d'encouragements** - Système de soutien mutuel
- **Classements** (optionnel) - Comparaison amicale

**Objectif :** Créer une communauté motivante et bienveillante

#### Paramètres

**Options Disponibles :**
- **Gestion du son** - Musique et effets sonores
- **Notifications** - Rappels de quêtes, récompenses
- **Langue** - Internationalisation
- **Compte utilisateur** - Gestion du profil
- **Thème** - Clair/Sombre (si applicable)
- **Sauvegarde** - Synchronisation cloud

---

## 4. Structure de Navigation (UI)

### 4.1 Header (En-tête)

**Éléments Toujours Visibles :**

- **Or** - Monnaie principale (affichage du montant)
- **Cristaux** - Monnaie premium (affichage du montant)
- **Accès aux paramètres** - Icône de menu/paramètres

**Position :** En haut de l'écran, fixe ou sticky selon le contexte

### 4.2 Footer Bar (Barre de Navigation)

**Navigation Persistante** avec icônes illustrées :

| Icône | Destination | Description |
|-------|-------------|-------------|
| 🏠 **Maison** | Home / Sanctuaire | Page principale avec avatar et quêtes |
| 📜 **Parchemin** | Quêtes | Liste complète des quêtes |
| 🎒 **Sac** | Inventaire | Le Coffre Astral - Gestion des objets |
| ⚔️ **Épée** | Customisation | Le Miroir des Âmes - Personnalisation |
| 🏪 **Boutique** | Marché | Le Marché Astral - Achat d'objets |
| 🎮 **Manette** | Mini-Jeux | Sélection et accès aux mini-jeux |
| 👤 **Tête** | Profil | Le Hall des Héros - Statistiques |

**Caractéristiques :**
- **Toujours visible** (sauf sur certaines pages modales)
- **Indicateur actif** sur l'onglet courant
- **Animations** au changement d'onglet
- **Badges** pour notifications (si applicable)

### 4.3 Navigation Secondaire

**Pages Accessibles depuis les Onglets :**

- **Depuis Quêtes** :
  - Création de quête (Le Grimoire)
  - Détails d'une quête
  - Historique des quêtes

- **Depuis Inventaire** :
  - Détails d'un objet
  - Équipement rapide

- **Depuis Customisation** :
  - Prévisualisation complète
  - Gestion des familiers

- **Depuis Profil** :
  - Paramètres
  - Succès détaillés
  - Historique complet

### 4.4 Transitions et Animations

**Principes :**
- **Transitions fluides** entre les pages
- **Animations contextuelles** (particules, glows)
- **Feedback visuel** sur les interactions
- **Chargement progressif** pour les assets lourds

---

## 5. Systèmes de Gameplay

### 5.1 Système d'Expérience et Niveaux

**Mécanique :**
- Gain d'XP par quête complétée
- Progression de niveau avec seuils
- Déblocage de fonctionnalités par niveau
- Récompenses de niveau

### 5.2 Système Économique

**Monnaies :**
- **Or** - Monnaie principale, gagnée via les quêtes
- **Cristaux** - Monnaie premium, achat ou récompenses spéciales

**Utilisation :**
- Achat d'objets dans la boutique
- Invocations premium
- Améliorations spéciales

### 5.3 Système de Bonus/Malus

**Mécanique :**
- **Bonus** pour complétion précoce ou streak
- **Malus** pour retard ou échec
- Impact sur les récompenses
- Affichage visuel clair

### 5.4 Système de Streak

**Fonctionnalité :**
- Compteur de jours consécutifs
- Récompenses bonus pour les streaks
- Visualisation claire dans le profil
- Motivation pour la constance

---

## 6. Expérience Utilisateur (UX)

### 6.1 Principes UX

**Clarté :**
- Informations importantes toujours visibles
- Feedback immédiat sur les actions
- Messages d'erreur clairs et constructifs

**Immersion :**
- Design cohérent avec l'univers fantasy
- Animations et effets visuels subtils
- Son et musique (optionnels)

**Motivation :**
- Récompenses visibles et gratifiantes
- Progression claire et tangible
- Sentiment d'accomplissement

### 6.2 Parcours Utilisateur Type

**Première Utilisation :**
1. Splash Screen → Onboarding
2. Authentification
3. Sanctuaire (tutoriel optionnel)
4. Création de première quête
5. Complétion et récompense

**Utilisation Quotidienne :**
1. Ouverture → Sanctuaire
2. Consultation des quêtes du jour
3. Complétion des quêtes
4. Collecte des récompenses
5. Consultation de la progression
6. Personnalisation (optionnel)

### 6.3 Points d'Attention UX

- **Temps de chargement** - Optimisation des assets
- **Accessibilité** - Contraste, taille de texte
- **Performance** - Fluidité des animations
- **Feedback** - Confirmation des actions importantes

---

## 7. Architecture Technique (Aperçu)

### 7.1 Stack Technologique

- **Framework** : Flutter
- **Backend** : Firebase / Supabase (authentification, données)
- **Stockage Local** : Hive
- **State Management** : Provider
- **Animations** : Rive, Lottie
- **Audio** : Just Audio

### 7.2 Structure des Données

**Entités Principales :**
- **Utilisateur** - Profil, statistiques, progression
- **Quête** - Tâches, récompenses, état
- **Item** - Objets, équipements, rareté
- **Inventaire** - Collection d'items
- **Équipement** - Items actuellement équipés

---

## 8. Roadmap et Évolutions Futures

### 8.1 Fonctionnalités Prioritaires

- ✅ Système de quêtes complet
- ✅ Personnalisation d'avatar
- ✅ Mini-jeux de base
- ✅ Marché et invocations
- 🔄 Système social (en développement)
- 🔄 Synchronisation cloud complète

### 8.2 Améliorations Continues

- Optimisation des performances
- Nouveaux mini-jeux
- Événements spéciaux
- Nouveaux objets et équipements
- Amélioration de l'IA du familier

---

## 9. Conclusion

Sameva est conçue pour être une **expérience complète et immersive** qui transforme la productivité en aventure. L'application combine :

- **Design soigné** avec une identité visuelle forte
- **Mécaniques de jeu** engageantes et motivantes
- **Progression tangible** et gratifiante
- **Personnalisation** profonde de l'expérience

L'objectif final est de créer une **habitude positive** où l'utilisateur revient quotidiennement, non pas par obligation, mais par plaisir et motivation intrinsèque.

---

**Document créé le** : 2024  
**Version** : 1.0  
**Statut** : Documentation complète

