# Documentation - Marché et Invocation

## 🛒 Vue d'ensemble

Le marché et le système d'invocation permettent aux utilisateurs d'obtenir de nouveaux items pour améliorer leur personnage. Le marché propose des achats directs avec de l'or, tandis que l'invocation offre des items aléatoires avec différents types de tirages.

---

## 🛒 Page Marché

**Fichier** : `lib/pages/market/market_page.dart`

### Description

Page permettant d'acheter des items avec l'or du joueur. Affiche tous les items disponibles organisés par catégories avec leurs prix et caractéristiques.

### Éléments UI

#### En-tête
- **Titre** : "Marché"
- **Or disponible** : Affichage de l'or du joueur
  - Icône : Pièce d'or
  - Montant : "X or"
  - Couleur : Or (`#F59E0B`)

#### Filtres et Recherche
- **Onglets de catégories** :
  - Tous
  - Armes
  - Armures
  - Casques
  - Boucliers
  - Potions
  - Consommables
- **Filtre de rareté** : Dropdown ou boutons
- **Recherche** : Barre de recherche (optionnel)
- **Tri** : Par prix, rareté, nom

#### Grille d'Items
- **Layout** : Grille responsive (2-3 colonnes)
- **Cartes d'items** :
  - **Image** : Image de l'item (assets/icons/items/)
  - **Nom** : Nom de l'item
  - **Rareté** : Badge coloré selon rareté
  - **Prix** : "X or" avec icône
  - **Stats** : Attaque, défense, PV (si applicable)
  - **Bouton "Acheter"** : Bouton principal
    - Désactivé si or insuffisant
    - Désactivé si inventaire plein

#### Modal de Détails
- **Image** : Grande image de l'item
- **Nom et description** : Texte complet
- **Rareté** : Badge avec couleur
- **Stats détaillées** :
  - Attaque (si arme)
  - Défense (si armure/bouclier)
  - PV bonus (si applicable)
  - Autres stats
- **Prix** : "X or"
- **Boutons** :
  - "Acheter" (si assez d'or)
  - "Fermer"

### Fonctionnalités

1. **Affichage des Items**
   - Récupération depuis `ItemFactory.createDefaultItems()`
   - Filtrage par type et rareté
   - Tri personnalisable
   - Recherche par nom (optionnel)

2. **Achat d'Items**
   - **Vérifications** :
     - Or suffisant
     - Espace dans l'inventaire (max 50 slots)
   - **Processus** :
     1. Tap sur "Acheter"
     2. Vérification des conditions
     3. Déduction de l'or (`PlayerProvider.addGold(-price)`)
     4. Ajout à l'inventaire (`InventoryProvider.addItem()`)
     5. Confirmation visuelle (SnackBar)
   - **Gestion des erreurs** :
     - "Or insuffisant" → Message + lien pour gagner de l'or
     - "Inventaire plein" → Message + lien vers inventaire

3. **Feedback**
   - Animation d'achat (optionnel)
   - SnackBar de confirmation
   - Mise à jour de l'or en temps réel
   - Vibration (optionnel)

### Items Disponibles

#### Armes
- **Commun** :
  - Épée en bois (50 or)
  - Hache simple (60 or)
  - Marteau basique (70 or)
- **Peu Commun** :
  - Hache améliorée (200 or)
  - Dague (150 or)
  - Baguette (180 or)
- **Rare** :
  - Hache double (400 or)
  - Arc amélioré (450 or)
  - Dague améliorée (500 or)
- **Très Rare** :
  - Hache double améliorée (800 or)
  - Marteau amélioré (750 or)
  - Baguette améliorée (900 or)
- **Épique** :
  - Épée épique (1500 or)
  - Lance épique (1600 or)

#### Armures
- **Commun** :
  - Armure de cuir (80 or)
- **Peu Commun** :
  - Armure renforcée (250 or)

#### Casques
- **Commun** :
  - Casque basique (60 or)
- **Peu Commun** :
  - Casque amélioré (200 or)

#### Boucliers
- **Commun** :
  - Petit bouclier (100 or)
  - Grand bouclier (300 or)
- **Rare** :
  - Bouclier amélioré (600 or)
  - Petit bouclier amélioré (500 or)

#### Potions
- **Commun** :
  - Potion de soin (30 or)
- **Peu Commun** :
  - Potion d'expérience (100 or)
  - Potion d'or (150 or)

#### Consommables
- **Commun** :
  - Parchemin (40 or)
  - Pièce d'or (50 or)
- **Peu Commun** :
  - Tome (120 or)

### Design

- **Layout** : Grille avec scroll vertical
- **Cartes** : `FantasyCard` avec bordures colorées selon rareté
- **Badges** : Couleurs selon rareté (voir Design System)
- **Boutons** : Style fantasy avec glow
- **Animations** : Hover effects, animations d'achat

---

## ✨ Page Invocation

**Fichier** : `lib/pages/invocation/invocation_page.dart`

### Description

Page permettant d'invoquer des items aléatoires avec différents types d'invocations. Chaque invocation a des probabilités différentes selon le type choisi.

### Éléments UI

#### En-tête
- **Titre** : "Invocation"
- **Sous-titre** : "Invoquez des items puissants !"

#### Ressources
- **Carte Or** :
  - Icône : Pièce d'or
  - Label : "Or"
  - Montant : "X or"
  - Couleur : Or (`#F59E0B`)
- **Carte Cristaux** :
  - Icône : Diamant
  - Label : "Cristaux"
  - Montant : "X cristaux"
  - Couleur : Cyan

#### Types d'Invocations

**1. Invocation Gratuite**
- **Titre** : "Invocation Gratuite"
- **Description** : "1 invocation gratuite par jour"
- **Icône** : Cadeau (`Icons.card_giftcard`)
- **Couleur** : Vert (`AppColors.success`)
- **Coût** : Gratuit
- **Limite** : 1 par jour (reset à minuit)

**2. Invocation Standard**
- **Titre** : "Invocation Standard"
- **Description** : "100 pièces d'or"
- **Icône** : Pièce d'or (`Icons.monetization_on`)
- **Couleur** : Or (`#F59E0B`)
- **Coût** : 100 or
- **Limite** : Illimitée (si assez d'or)

**3. Invocation Premium**
- **Titre** : "Invocation Premium"
- **Description** : "10 cristaux (meilleures chances)"
- **Icône** : Diamant (`Icons.diamond`)
- **Couleur** : Cyan
- **Coût** : 10 cristaux
- **Limite** : Illimitée (si assez de cristaux)
- **Bonus** : Probabilités améliorées (futur)

#### Carte des Probabilités
- **Titre** : "Probabilités"
- **Liste** :
  - Mythique : 1% (Rouge)
  - Légendaire : 4% (Or)
  - Épique : 10% (Orange)
  - Très Rare : 20% (Violet)
  - Rare : 30% (Bleu)
  - Peu Commun : 20% (Vert)
  - Commun : 15% (Gris)

### Fonctionnalités

1. **Invocation**
   - **Processus** :
     1. Sélection du type d'invocation
     2. Vérification des ressources (or/cristaux)
     3. Affichage de l'animation (`InvocationAnimation`)
     4. Calcul aléatoire de la rareté selon probabilités
     5. Création de l'item selon la rareté
     6. Déduction des ressources
     7. Ajout à l'inventaire
     8. Affichage du résultat (SnackBar)

2. **Calcul de Rareté**
   ```dart
   final random = Random().nextDouble();
   
   if (random < 0.01) return ItemRarity.mythic;      // 1%
   if (random < 0.05) return ItemRarity.legendary;  // 4%
   if (random < 0.15) return ItemRarity.epic;        // 10%
   if (random < 0.35) return ItemRarity.veryRare;    // 20%
   if (random < 0.65) return ItemRarity.rare;        // 30%
   if (random < 0.85) return ItemRarity.uncommon;    // 20%
   return ItemRarity.common;                          // 15%
   ```

3. **Création d'Item**
   - Sélection d'un item aléatoire de la rareté obtenue
   - Depuis `ItemFactory.createDefaultItems()`
   - Si aucun item de cette rareté, création d'un item basique

4. **Animation**
   - **Widget** : `InvocationAnimation`
   - **Effets** : Particules, glow, couleurs selon rareté
   - **Durée** : 2-3 secondes
   - **Callback** : `onComplete()` après l'animation

5. **Gestion des Limites**
   - **Gratuite** : Vérification de la dernière invocation
   - **Reset** : À minuit (heure locale)
   - **Affichage** : "Disponible" ou "Déjà utilisée aujourd'hui"

### Design

- **Layout** : Liste verticale avec cartes
- **Cartes** : `FantasyCard` avec bordures colorées
- **Animations** : Transitions, effets de glow
- **Couleurs** : Selon le type et la rareté

---

## 🎁 Système de Récompenses

### Items Obtenus

Les items invoqués sont ajoutés automatiquement à l'inventaire avec :
- **ID unique** : Généré automatiquement
- **Rareté** : Selon le tirage
- **Stats** : Selon le type d'item
- **Image** : Asset correspondant

### Gestion des Doublons

- **Items uniques** : Ajoutés normalement
- **Consommables** : Empilés si même type
- **Inventaire plein** : Message d'erreur, item non ajouté

---

## 🔧 Intégration Technique

### Providers Utilisés

**PlayerProvider** :
- `stats.gold` : Or disponible
- `stats.crystals` : Cristaux disponibles
- `addGold()` : Déduction de l'or
- `spendCrystals()` : Déduction des cristaux

**InventoryProvider** :
- `addItem()` : Ajout à l'inventaire
- `hasSpace()` : Vérification de l'espace

**ItemFactory** :
- `createDefaultItems()` : Liste des items disponibles
- `createQuestRewardItem()` : Création d'item selon rareté

### Stockage

- **Hive** : Inventaire local
- **Firestore** : Synchronisation (optionnel)
- **SharedPreferences** : Limite d'invocation gratuite

---

## 🎨 Design et UX

### Principes

1. **Clarté** : Prix et coûts visibles
2. **Feedback** : Animations et confirmations
3. **Motivation** : Probabilités affichées
4. **Accessibilité** : Boutons désactivés si conditions non remplies

### Animations

- **Achat** : Animation de succès
- **Invocation** : Animation spectaculaire
- **Transitions** : Fade et slide
- **Feedback** : Vibrations (optionnel)

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Or insuffisant** :
   - Message : "Or insuffisant (X or requis)"
   - Action : Lien pour gagner de l'or

2. **Cristaux insuffisants** :
   - Message : "Cristaux insuffisants (X cristaux requis)"
   - Action : Lien pour obtenir des cristaux

3. **Inventaire plein** :
   - Message : "Inventaire plein (50/50)"
   - Action : Lien vers l'inventaire

4. **Invocation gratuite déjà utilisée** :
   - Message : "Invocation gratuite déjà utilisée aujourd'hui"
   - Action : Affichage du temps restant

5. **Erreur de chargement** :
   - Message : "Erreur lors de l'invocation"
   - Action : Bouton "Réessayer"

---

## 📊 Statistiques

### Métriques Suivies

1. **Achats** :
   - Nombre total d'achats
   - Or dépensé
   - Items achetés par type

2. **Invocations** :
   - Nombre total d'invocations
   - Répartition par rareté
   - Taux de rareté obtenu

3. **Efficacité** :
   - Coût moyen par item
   - Valeur moyenne des items obtenus

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Pack d'invocations (10+1 gratuit)
- [ ] Invocations garanties (pity system)
- [ ] Invocations limitées (événements)
- [ ] Historique d'achats/invocations
- [ ] Favoris d'items
- [ ] Comparaison d'items
- [ ] Prévisualisation avant achat
- [ ] Système de vente d'items
- [ ] Échange entre joueurs
- [ ] Marché aux enchères

