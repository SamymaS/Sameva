# Documentation - Pages Principales

## 🏠 Vue d'ensemble

Les pages principales constituent le cœur de l'application Sameva. Elles sont accessibles via la barre de navigation inférieure et offrent les fonctionnalités essentielles de l'application.

---

## 📱 Navigation Principale

### Barre de Navigation Inférieure

**Fichier** : `lib/app_new.dart`

La barre de navigation contient **5 onglets principaux** :

1. 🏠 **Accueil** - Page d'accueil avec quêtes du jour
2. 🛒 **Marché** - Achat d'items
3. ✨ **Invocation** - Système d'invocation d'items
4. 👤 **Avatar** - Personnalisation de l'avatar
5. 🎮 **Mini-Jeux** - Liste des mini-jeux disponibles

**Design** :
- Fond sombre (`Color(0xFF111624)`)
- Indicateur de sélection avec couleur accent
- Icônes Material Design
- Labels sous les icônes
- Animation de transition entre pages

**Fonctionnalités** :
- Navigation fluide avec `AnimatedSwitcher`
- Transitions fade + slide
- Conservation de l'état de chaque page
- Indicateur visuel de la page active

---

## 1. Page d'Accueil

**Fichier** : `lib/pages/home/new_home_page.dart`

### Description

Page principale de l'application. Affiche un aperçu des quêtes du jour, les statistiques du joueur, et des accès rapides aux fonctionnalités principales.

### Éléments UI

#### En-tête
- **Logo/Titre** : "Sameva" centré
- **Bouton Profil** : Icône personne (en haut à gauche)
- **Bouton Paramètres** : Icône engrenage (en haut à droite)

#### Fond Animé
- **AnimatedBackground** : Fond avec animation subtile
- Gradient ou particules animées
- Couleur : Palette fantasy

#### Bouton Principal
- **"Créer une quête"** : Bouton principal avec glow
- Icône : `Icons.add`
- Couleur : Or (`#F59E0B`)
- Navigation vers la page de création de quête

#### Section "Quêtes du jour"
- **Titre** : "Quêtes du jour"
- **Liste de quêtes** : Cartes pour chaque quête active
- **Bouton "Voir tout"** : Navigation vers la liste complète
- Affichage :
  - Titre de la quête
  - Rareté (badge coloré)
  - Progression (si sous-quêtes)
  - Temps restant
  - Bouton "Voir détails"

#### Statistiques du Joueur
- **Carte de stats** : Widget `PlayerStatsCard`
- Affichage :
  - Niveau actuel
  - Barre d'expérience (XP actuelle / XP requise)
  - Points de vie (PV actuel / PV max)
  - Or disponible
  - Cristaux disponibles
  - Streak (jours consécutifs)

#### Accès Rapides
- **Boutons d'action rapide** :
  - "Mes Quêtes" → Liste complète
  - "Inventaire" → Page inventaire
  - "Profil" → Page profil

### Fonctionnalités

1. **Affichage des quêtes actives**
   - Récupération depuis `QuestProvider`
   - Filtrage par date (quêtes du jour)
   - Tri par priorité/rareté

2. **Mise à jour en temps réel**
   - Écoute des changements de quêtes
   - Mise à jour des statistiques
   - Rafraîchissement automatique

3. **Navigation**
   - Vers création de quête
   - Vers détails de quête
   - Vers liste complète
   - Vers profil et paramètres

### Design

- **Layout** : Scroll vertical
- **Couleurs** : Palette fantasy (violet, or)
- **Composants** : `FantasyCard`, `FantasyButton`, `FantasyBadge`
- **Animations** : Transitions subtiles, hover effects

### Widgets Utilisés

- `PlayerStatsCard` : Carte de statistiques
- `QuestList` : Liste de quêtes
- `FantasyButton` : Boutons stylisés
- `AnimatedBackground` : Fond animé

---

## 2. Page Marché

**Fichier** : `lib/pages/market/market_page.dart`

### Description

Page permettant d'acheter des items avec l'or du joueur. Affiche tous les items disponibles à l'achat, organisés par catégories.

### Éléments UI

#### En-tête
- **Titre** : "Marché"
- **Or du joueur** : Affichage de l'or disponible
- **Icône** : Pièce d'or

#### Filtres
- **Onglets ou boutons** :
  - Tous
  - Armes
  - Armures
  - Potions
  - Consommables
  - Par rareté

#### Grille d'Items
- **Cartes d'items** : Grille responsive
- **Informations affichées** :
  - Image de l'item
  - Nom
  - Rareté (badge coloré)
  - Prix (en or)
  - Stats (attaque, défense, etc.)
  - Bouton "Acheter"

#### Détails d'Item (Modal)
- **Image** : Grande image de l'item
- **Nom et description**
- **Stats détaillées**
- **Prix**
- **Bouton "Acheter"** ou "Fermer"

### Fonctionnalités

1. **Affichage des items**
   - Récupération depuis `ItemFactory.createDefaultItems()`
   - Filtrage par type et rareté
   - Tri par prix ou rareté

2. **Achat d'items**
   - Vérification de l'or disponible
   - Vérification de l'espace dans l'inventaire
   - Déduction de l'or
   - Ajout à l'inventaire
   - Confirmation visuelle (SnackBar)

3. **Gestion des erreurs**
   - "Or insuffisant"
   - "Inventaire plein"
   - Affichage des messages d'erreur

### Design

- **Layout** : Grille avec scroll
- **Cartes** : `FantasyCard` avec bordures
- **Animations** : Hover effects, animations d'achat
- **Couleurs** : Badges de rareté

### Items Disponibles

- **Armes** : Épées, haches, dagues, arcs, marteaux, baguettes
- **Armures** : Cuir, renforcées
- **Casques** : Basiques, améliorés
- **Boucliers** : Petits, grands, améliorés
- **Potions** : Soin, expérience, or
- **Consommables** : Parchemins, tomes, pièces

---

## 3. Page Invocation

**Fichier** : `lib/pages/invocation/invocation_page.dart`

### Description

Page permettant d'invoquer des items aléatoires avec différents types d'invocations (gratuit, or, premium).

### Éléments UI

#### En-tête
- **Titre** : "Invocation"
- **Sous-titre** : "Invoquez des items puissants !"

#### Ressources
- **Carte Or** :
  - Icône : Pièce d'or
  - Montant disponible
  - Couleur : Or
- **Carte Cristaux** :
  - Icône : Diamant
  - Montant disponible
  - Couleur : Cyan

#### Types d'Invocations

**1. Invocation Gratuite**
- **Titre** : "Invocation Gratuite"
- **Description** : "1 invocation gratuite par jour"
- **Icône** : Cadeau
- **Couleur** : Vert (success)
- **Coût** : Gratuit

**2. Invocation Standard**
- **Titre** : "Invocation Standard"
- **Description** : "100 pièces d'or"
- **Icône** : Pièce d'or
- **Couleur** : Or
- **Coût** : 100 or

**3. Invocation Premium**
- **Titre** : "Invocation Premium"
- **Description** : "10 cristaux (meilleures chances)"
- **Icône** : Diamant
- **Couleur** : Cyan
- **Coût** : 10 cristaux

#### Probabilités
- **Carte des probabilités** :
  - Mythique : 1%
  - Légendaire : 4%
  - Épique : 10%
  - Très Rare : 20%
  - Rare : 30%
  - Peu Commun : 20%
  - Commun : 15%

### Fonctionnalités

1. **Invocation**
   - Sélection du type d'invocation
   - Vérification des ressources
   - Animation d'invocation (`InvocationAnimation`)
   - Calcul aléatoire de la rareté
   - Création de l'item selon la rareté
   - Ajout à l'inventaire
   - Déduction des ressources

2. **Animation**
   - Effet visuel selon la rareté
   - Particules et effets
   - Révélation de l'item

3. **Feedback**
   - SnackBar avec le nom de l'item obtenu
   - Couleur selon la rareté
   - Message de succès ou d'erreur

### Design

- **Layout** : Liste verticale avec cartes
- **Cartes** : `FantasyCard` avec bordures colorées
- **Animations** : Transitions, effets de glow
- **Couleurs** : Selon la rareté et le type

---

## 4. Page Avatar

**Fichier** : `lib/pages/avatar/avatar_page.dart`

### Description

Page de personnalisation de l'avatar. Permet d'équiper des tenues, auras, armes, boucliers et compagnons.

Voir **[DOCUMENTATION_PERSONNALISATION.md](./DOCUMENTATION_PERSONNALISATION.md)** pour plus de détails.

---

## 5. Page Mini-Jeux

**Fichier** : `lib/pages/minigame/minigame_page.dart`

### Description

Page listant tous les mini-jeux disponibles. Permet de lancer chaque jeu individuellement.

Voir **[DOCUMENTATION_MINI_JEUX.md](./DOCUMENTATION_MINI_JEUX.md)** pour plus de détails.

---

## 🔗 Pages Secondaires

### Page Profil

**Route** : `/profile`

**Fichier** : `lib/pages/profile/profile_page.dart`

**Description** :
- Affichage des statistiques complètes
- Historique des quêtes
- Progression globale
- Options de personnalisation

### Page Paramètres

**Route** : `/settings`

**Fichier** : `lib/pages/settings/settings_page.dart`

**Description** :
- Paramètres de l'application
- Thème (clair/sombre)
- Notifications
- Déconnexion
- À propos

### Page Inventaire

**Route** : `/inventory`

**Fichier** : `lib/pages/inventory/inventory_page.dart`

**Description** :
- Gestion complète de l'inventaire
- Organisation par type
- Utilisation d'items
- Équipement

Voir **[DOCUMENTATION_PERSONNALISATION.md](./DOCUMENTATION_PERSONNALISATION.md)** pour plus de détails.

### Page Liste des Quêtes

**Route** : `/quests`

**Fichier** : `lib/pages/quest/quests_list_page.dart`

**Description** :
- Liste complète de toutes les quêtes
- Filtres : Actives, Terminées, Archivées
- Recherche
- Tri par date/rareté

Voir **[DOCUMENTATION_QUETES.md](./DOCUMENTATION_QUETES.md)** pour plus de détails.

---

## 🎨 Design Commun

### Principes

1. **Cohérence** : Même style sur toutes les pages
2. **Navigation claire** : Toujours un moyen de revenir
3. **Feedback visuel** : Animations et transitions
4. **Accessibilité** : Contrastes suffisants, tailles lisibles

### Composants Réutilisables

- `FantasyCard` : Cartes avec style fantasy
- `FantasyButton` : Boutons avec glow
- `FantasyBadge` : Badges de statut
- `FantasyAvatar` : Avatars
- `FantasyBanner` : Bannières
- `FantasyTitle` : Titres stylisés

### Animations

- **Transitions** : Fade + slide entre pages
- **Hover effects** : Sur les cartes et boutons
- **Loading states** : Spinners et skeletons
- **Success feedback** : Animations de confirmation

---

## 📱 Responsive Design

### Adaptation

- **Mobile** : Layout optimisé pour petits écrans
- **Tablette** : Grilles plus larges, plus d'éléments visibles
- **Orientation** : Support portrait (paysage optionnel)

### Breakpoints

- **Petit** : < 600px (1 colonne)
- **Moyen** : 600-900px (2 colonnes)
- **Grand** : > 900px (3+ colonnes)

---

## 🔄 Gestion d'État

### Providers Utilisés

- `PlayerProvider` : Statistiques du joueur
- `QuestProvider` : Quêtes
- `InventoryProvider` : Inventaire
- `EquipmentProvider` : Équipement
- `AuthProvider` : Authentification

### Mise à Jour

- **Temps réel** : Écoute des changements
- **Rafraîchissement** : Pull-to-refresh (si nécessaire)
- **Cache** : Données mises en cache localement

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Pas de connexion** : Message + bouton réessayer
2. **Données manquantes** : Affichage d'un état vide
3. **Erreur de chargement** : Message + retry

### États Vides

- **Pas de quêtes** : Message "Aucune quête" + bouton créer
- **Inventaire vide** : Message + lien vers le marché
- **Pas d'items** : Message approprié

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Recherche dans le marché
- [ ] Favoris d'items
- [ ] Historique d'achats
- [ ] Notifications push
- [ ] Mode hors ligne
- [ ] Partage de progression






