# Système Complet de Sameva

## Vue d'ensemble

Sameva est maintenant une application professionnelle complète pour organiser son quotidien avec des quêtes, se détendre avec des mini-jeux, et personnaliser son avatar. Le système inclut :

## 🎯 Fonctionnalités Principales

### 1. Système de Quêtes
- **Création et gestion de quêtes** : Quêtes quotidiennes, hebdomadaires, mensuelles ou uniques
- **Système de rareté** : Commun, Peu commun, Rare, Très rare, Épique, Légendaire, Mythique
- **Récompenses dynamiques** : Basées sur la difficulté, la ponctualité et les bonus/malus
- **Suivi de progression** : Quêtes actives, complétées, archivées

### 2. Système d'Expérience et de Leveling
- **Niveaux** : Progression basée sur l'expérience gagnée
- **Formule de niveau** : `XP requis = 100 × (niveau × 1.5)`
- **Augmentation des PV max** : +10 PV par niveau
- **Gain d'expérience** : Via quêtes complétées, mini-jeux, items

### 3. Système de Bonus/Malus
Le système calcule automatiquement les bonus/malus basés sur :

#### Bonus
- **Complétion quotidienne** :
  - 100% complétées : +50% récompenses
  - 80%+ complétées : +30% récompenses
  - 50%+ complétées : +10% récompenses
- **Streak (jours consécutifs)** :
  - 30+ jours : +40% récompenses
  - 14+ jours : +30% récompenses
  - 7+ jours : +20% récompenses
  - 3+ jours : +10% récompenses
- **Ponctualité** :
  - Terminée en avance (20%+) : +25% récompenses
  - Terminée à temps : +10% récompenses

#### Malus
- **Quêtes manquées** :
  - 50%+ manquées : -30% récompenses
  - 25%+ manquées : -15% récompenses
- **Inactivité** :
  - 7+ jours : -40% récompenses
  - 3+ jours : -25% récompenses
  - 1 jour : -10% récompenses
- **Retard** : -20% récompenses si terminée après l'échéance

### 4. Système de Points de Vie (PV)
- **PV de base** : 100 PV au niveau 1
- **PV max** : Augmente avec le niveau (+10 par niveau)
- **Régénération automatique** :
  - Base : 1% des PV max par heure
  - Bonus si quêtes complétées : +50% selon taux de complétion
  - Bonus de streak : +20% pour streak 7+
  - Malus si moral bas : -50% si moral < 0.5
- **Régénération après quête** : +10% PV max si complétée à temps ou en avance
- **Perte de PV** :
  - Inactivité : -2% PV max par quête manquée (max 20%)
  - Moral très bas (< 0.2) : -5% PV max progressivement
- **Mort** : Si PV = 0, le joueur est réinitialisé (niveau 1, perte de la moitié de l'or, pénalité de crédibilité)

### 5. Système d'Inventaire
- **Capacité** : 50 slots maximum
- **Empilement** : Items consommables empilables jusqu'à leur `stackSize`
- **Organisation** : Filtres par type (Tous, Équipement, Consommables)
- **Gestion** : Ajout, retrait, utilisation d'items

### 6. Système d'Équipement
- **Slots d'équipement** :
  - Arme
  - Armure
  - Casque
  - Bouclier
  - Tenue (cosmétique)
  - Aura (cosmétique)
- **Bonus d'équipement** :
  - Armes : Bonus d'attaque
  - Armures/Casques : Bonus de défense et PV
  - Boucliers : Bonus de défense
- **Affichage** : L'avatar affiche l'équipement actuel

### 7. Système de Compagnon
- **Gestion** : Un compagnon peut être assigné au joueur
- **Stats** : Niveau, expérience, PV
- **Personnalisation** : Tenue équipable sur le compagnon

### 8. Marché
- **Achat d'items** : Utilisation de l'or pour acheter des items
- **Items disponibles** : Armes, armures, potions, etc.
- **Vérifications** : Or suffisant, place dans l'inventaire

### 9. Mini-Jeux
- **Memory Quest** : Jeu de mémoire avec séquences
- **Speed Challenge** : Défi de rapidité
- **Puzzle Quest** : Puzzle de tuiles

## 📁 Structure des Fichiers

### Modèles de Données
- `lib/core/models/item.dart` : Modèle Item et InventorySlot
- `lib/core/models/equipment.dart` : Modèle PlayerEquipment et Companion

### Providers
- `lib/core/providers/inventory_provider.dart` : Gestion de l'inventaire
- `lib/core/providers/equipment_provider.dart` : Gestion de l'équipement
- `lib/core/providers/player_provider.dart` : Stats du joueur (amélioré)
- `lib/core/providers/quest_provider.dart` : Gestion des quêtes (amélioré)

### Services
- `lib/services/bonus_malus_service.dart` : Calcul des bonus/malus
- `lib/services/health_regeneration_service.dart` : Régénération des PV
- `lib/services/item_factory.dart` : Création d'items prédéfinis

### Pages
- `lib/pages/inventory/inventory_page.dart` : Page d'inventaire complète
- `lib/pages/avatar/avatar_page.dart` : Page d'avatar avec équipement réel
- `lib/pages/market/market_page.dart` : Marché fonctionnel avec achat
- `lib/pages/quest/quest_detail_page.dart` : Détails de quête avec récompenses

## 🔧 Utilisation

### Compléter une Quête
1. Ouvrir une quête depuis la liste
2. Cliquer sur "Terminer la quête"
3. Les récompenses sont calculées automatiquement avec bonus/malus
4. L'expérience, l'or et les items sont ajoutés automatiquement

### Équiper un Item
1. Aller dans l'inventaire
2. Sélectionner l'onglet "Équipement"
3. Cliquer sur "Équiper" sur un item équipable
4. L'item est automatiquement équipé et les bonus appliqués

### Acheter un Item
1. Aller au marché
2. Parcourir les items disponibles
3. Cliquer sur "Acheter" (si assez d'or)
4. L'item est ajouté à l'inventaire

### Utiliser un Consommable
1. Aller dans l'inventaire
2. Sélectionner l'onglet "Consommables"
3. Cliquer sur "Utiliser"
4. Les effets sont appliqués (soin, XP, or)

## 🎮 Système de Gameplay

### Progression
- Compléter des quêtes pour gagner de l'XP et monter en niveau
- Maintenir un streak pour des bonus de récompenses
- Équiper des items pour améliorer ses stats
- Gérer ses PV pour éviter la mort

### Stratégie
- Compléter les quêtes à temps pour maximiser les récompenses
- Maintenir un moral élevé pour éviter les pénalités
- Équiper des items adaptés à son style de jeu
- Utiliser les potions stratégiquement

## 📊 Statistiques Suivies

- **Niveau** : Progression du joueur
- **Expérience** : XP actuelle et nécessaire pour le prochain niveau
- **Or** : Monnaie principale
- **Cristaux** : Monnaie premium
- **PV** : Points de vie actuels et maximum
- **Moral** : Énergie/motivation (0.0 à 1.0)
- **Streak** : Jours consécutifs actifs
- **Crédibilité** : Score de fiabilité (0.0 à 1.0)

## 🔄 Intégrations

- **Quêtes → Récompenses** : Les quêtes donnent automatiquement des items selon leur rareté
- **Marché → Inventaire** : Les achats sont directement ajoutés à l'inventaire
- **Inventaire → Équipement** : Les items peuvent être équipés depuis l'inventaire
- **Équipement → Stats** : Les bonus d'équipement sont appliqués automatiquement
- **Quêtes → Bonus/Malus** : Les quêtes complétées/manquées affectent les récompenses futures

## 🚀 Améliorations Futures Possibles

- Système de guildes/communauté
- Quêtes collaboratives
- Événements spéciaux
- Plus de types d'items
- Système de craft
- Amélioration d'items
- Compagnons avec IA
- Système de trading entre joueurs


