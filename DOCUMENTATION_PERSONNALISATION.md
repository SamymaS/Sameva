# Documentation - Personnalisation et Inventaire

## 👤 Vue d'ensemble

Le système de personnalisation permet aux utilisateurs de customiser leur avatar avec des tenues, auras, armes, boucliers et compagnons. L'inventaire gère tous les items possédés par le joueur.

---

## 🎨 Page Avatar

**Fichier** : `lib/pages/avatar/avatar_page.dart`

### Description

Page principale de personnalisation de l'avatar. Permet d'équiper différents items pour modifier l'apparence et les stats du personnage.

### Éléments UI

#### En-tête
- **Titre** : "Personnalisation"

#### Avatar Principal
- **Preview** : Avatar avec équipement actuel
- **Stack** : Superposition des éléments
  - Base (tenue)
  - Aura (effet visuel)
  - Arme (à droite)
  - Bouclier (à gauche)
- **Badges** :
  - Niveau actuel
  - Rareté de l'équipement

#### Sections d'Équipement

**1. Tenues**
- **Titre** : "Tenues"
- **Description** : "Changez l'apparence de votre avatar"
- **Grille** : 3 colonnes
- **Items** : Toutes les tenues de l'inventaire
- **Action** : Tap pour équiper

**2. Auras**
- **Titre** : "Auras"
- **Description** : "Effets visuels pour votre avatar"
- **Grille** : 3 colonnes
- **Items** : Toutes les auras de l'inventaire
- **Action** : Tap pour équiper

**3. Armes**
- **Titre** : "Armes"
- **Description** : "Choisissez votre arme"
- **Grille** : 3 colonnes
- **Items** : Toutes les armes de l'inventaire
- **Action** : Tap pour équiper

**4. Boucliers**
- **Titre** : "Boucliers"
- **Description** : "Choisissez votre bouclier"
- **Grille** : 3 colonnes
- **Items** : Tous les boucliers de l'inventaire
- **Action** : Tap pour équiper

**5. Compagnons**
- **Titre** : "Compagnons"
- **Description** : "Choisissez votre compagnon"
- **Grille** : 3 colonnes
- **Items** : Tous les compagnons de l'inventaire
- **Action** : Tap pour équiper

### Fonctionnalités

1. **Affichage**
   - Récupération des items depuis `InventoryProvider`
   - Filtrage par type d'item
   - Affichage de l'équipement actuel depuis `EquipmentProvider`

2. **Équipement**
   - Tap sur un item → Équipement
   - Mise à jour de l'équipement dans `EquipmentProvider`
   - Mise à jour de l'avatar en temps réel
   - Badge "Équipé" sur l'item actuel

3. **Déséquipement**
   - Bouton "Déséquiper" si un item est équipé
   - Retrait de l'équipement
   - Retour à l'apparence par défaut

4. **Preview**
   - Affichage en temps réel de l'équipement
   - Superposition correcte des éléments
   - Animation subtile

### Design

- **Layout** : Liste verticale scrollable
- **Cartes** : `FantasyCard` pour chaque section
- **Grilles** : 3 colonnes avec `GridView`
- **Items** : Cartes avec image, nom, bordure si équipé
- **Couleurs** : Bordure colorée pour l'item équipé

---

## 🎒 Page Inventaire

**Fichier** : `lib/pages/inventory/inventory_page.dart`

### Description

Page de gestion complète de l'inventaire. Permet de voir, organiser, utiliser et équiper tous les items possédés.

### Éléments UI

#### En-tête
- **Titre** : "Inventaire"
- **Capacité** : "X/50 slots utilisés"
- **Bouton "Marché"** : Navigation vers le marché

#### Onglets
- **Tous** : Tous les items
- **Équipement** : Armes, armures, boucliers, casques
- **Consommables** : Potions, parchemins, tomes
- **Autres** : Items divers

#### Grille d'Items
- **Layout** : Grille responsive (2-3 colonnes)
- **Cartes d'items** :
  - Image de l'item
  - Nom
  - Rareté (badge coloré)
  - Quantité (si empilable)
  - Stats (si équipement)

#### Détails d'Item (Modal)
- **Image** : Grande image
- **Nom et description**
- **Rareté** : Badge coloré
- **Stats** : Attaque, défense, PV, etc.
- **Actions** :
  - "Utiliser" (si consommable)
  - "Équiper" (si équipement)
  - "Vendre" (optionnel)
  - "Fermer"

### Fonctionnalités

1. **Affichage**
   - Récupération depuis `InventoryProvider`
   - Filtrage par type
   - Tri par rareté, nom, date d'obtention
   - Groupement des items empilables

2. **Organisation**
   - Filtres par type
   - Recherche par nom
   - Tri personnalisable

3. **Utilisation**
   - **Consommables** : Utilisation immédiate
     - Potions : Restauration de PV
     - Parchemins : Gain d'XP
     - Tomes : Gain d'XP élevé
     - Pièces : Gain d'or
   - **Équipement** : Navigation vers page avatar

4. **Gestion**
   - Suppression d'items (avec confirmation)
   - Vente d'items (optionnel)
   - Organisation manuelle (optionnel)

### Design

- **Layout** : Grille avec scroll
- **Cartes** : `FantasyCard` avec images
- **Badges** : Couleurs selon rareté
- **Modal** : Détails en overlay

---

## 📦 Système d'Inventaire

### Capacité

- **Maximum** : 50 slots
- **Utilisés** : Nombre d'items uniques
- **Empilement** : Items consommables empilables

### Types d'Items

1. **Équipement**
   - Armes
   - Armures
   - Casques
   - Boucliers
   - Tenues (cosmétique)
   - Auras (cosmétique)

2. **Consommables**
   - Potions (soin, XP, or)
   - Parchemins (XP)
   - Tomes (XP élevé)
   - Pièces (or)

3. **Autres**
   - Items spéciaux
   - Ressources
   - Matériaux (futur)

### Modèle de Données

```dart
class Item {
  String id;
  String name;
  String? description;
  ItemType type;
  ItemRarity rarity;
  String? imagePath;
  int value; // Prix de vente
  Map<String, int>? stats; // Attaque, défense, etc.
  bool isEquippable;
  bool isConsumable;
  int? stackSize; // Pour les consommables
}
```

---

## 🛡️ Système d'Équipement

### Slots d'Équipement

1. **Arme** (`weaponId`)
   - Bonus d'attaque
   - Affichage à droite de l'avatar

2. **Armure** (`armorId`)
   - Bonus de défense et PV
   - Modifie l'apparence de base

3. **Casque** (`helmetId`)
   - Bonus de défense et PV
   - Affichage sur la tête

4. **Bouclier** (`shieldId`)
   - Bonus de défense
   - Affichage à gauche de l'avatar

5. **Tenue** (`outfitId`)
   - Cosmétique uniquement
   - Modifie l'apparence complète

6. **Aura** (`auraId`)
   - Cosmétique uniquement
   - Effet visuel autour de l'avatar

7. **Compagnon** (`companionId`)
   - Cosmétique uniquement
   - Affichage à côté de l'avatar

### Modèle de Données

```dart
class PlayerEquipment {
  String userId;
  String? weaponId;
  String? armorId;
  String? helmetId;
  String? shieldId;
  String? outfitId;
  String? auraId;
  String? companionId;
}
```

### Bonus d'Équipement

Les bonus sont calculés automatiquement :

```dart
final totalAttack = baseAttack + weaponAttack + (other bonuses);
final totalDefense = baseDefense + armorDefense + helmetDefense + shieldDefense;
final totalHealth = baseHealth + armorHealth + helmetHealth;
```

---

## 🎨 Assets et Images

### Structure des Assets

```
assets/
  images/
    avatars/        # Avatars de base
    items/          # Images d'items
    auras/          # Effets d'aura
    companions/     # Compagnons
    backgrounds/    # Fonds
  icons/
    items/          # Icônes d'items
```

### Formats Supportés

- **Images** : PNG, JPG
- **Taille recommandée** : 256x256px minimum
- **Optimisation** : Compression pour performance

---

## 🔧 Intégration Technique

### Providers

**InventoryProvider** (`lib/core/providers/inventory_provider.dart`) :
- `addItem()` : Ajouter un item
- `removeItem()` : Retirer un item
- `useItem()` : Utiliser un consommable
- `getItems()` : Récupérer les items
- `getEquippableItems()` : Items équipables
- `getConsumables()` : Items consommables

**EquipmentProvider** (`lib/core/providers/equipment_provider.dart`) :
- `equipItem()` : Équiper un item
- `unequipItem()` : Déséquiper un item
- `getEquipment()` : Récupérer l'équipement actuel

### Stockage

- **Hive** : Stockage local
  - Inventaire
  - Équipement
- **Firestore** : Synchronisation (optionnel)

---

## 🎁 Système de Récompenses

### Obtention d'Items

1. **Quêtes** : Items selon la rareté de la quête
2. **Marché** : Achat avec or
3. **Invocation** : Items aléatoires
4. **Mini-jeux** : Récompenses spéciales (futur)

### Rareté des Items

- **Commun** : Items de base
- **Peu Commun** : Items améliorés
- **Rare** : Items puissants
- **Très Rare** : Items très puissants
- **Épique** : Items exceptionnels
- **Légendaire** : Items rares
- **Mythique** : Items ultra-rares

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Inventaire plein** : "Inventaire plein (50/50)"
2. **Item non trouvé** : "Item introuvable"
3. **Erreur d'équipement** : "Impossible d'équiper cet item"
4. **Erreur d'utilisation** : "Impossible d'utiliser cet item"

### États Vides

- **Aucun item** : Message + lien vers le marché
- **Aucun item de ce type** : Message approprié
- **Inventaire vide** : Message + bouton "Aller au marché"

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Amélioration d'items
- [ ] Craft d'items
- [ ] Fusion d'items
- [ ] Enchantements
- [ ] Sets d'équipement (bonus de set)
- [ ] Prévisualisation 3D
- [ ] Animation d'équipement
- [ ] Historique d'items
- [ ] Favoris
- [ ] Organisation par dossiers
- [ ] Recherche avancée
- [ ] Filtres multiples
- [ ] Tri personnalisé


