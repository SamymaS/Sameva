# Analyse de phase MVP - Sameva

> **Date :** 10 février 2026  
> **Référence :** MVP_SAMEVA.md v2.0

---

## 📊 Résumé exécutif

**Phase actuelle :** Entre **Phase 3** (Système de quêtes) et **Phase 4** (Avatar & Inventaire)  
**Avancement global MVP :** ~**65-70%**

Le cœur fonctionnel (quêtes + auth + progression) est en place, mais les pages **Inventaire** et **Personnalisation Avatar** manquent, ainsi que certaines fonctionnalités critiques du MVP.

---

## ✅ Ce qui est IMPLÉMENTÉ (Phase 1 MVP)

### 🔴 Critiques - COMPLÈTES

| Fonctionnalité | État | Détails |
|----------------|------|---------|
| **Authentification** | ✅ **100%** | Login, Register, Onboarding, Anonymous. `AuthProvider` fonctionnel avec Supabase. |
| **Création de quêtes** | ✅ **95%** | `CreateQuestPage`, formulaire complet (titre, description, catégorie, difficulté, deadline). |
| **Liste des quêtes** | ✅ **95%** | `QuestsListPage` avec filtres actives/terminées, `QuestProvider` avec CRUD complet. |
| **Validation de quête** | ✅ **90%** | `QuestValidationPage` avec validation IA (photo/vidéo), timer, calcul récompenses. |
| **Système de récompenses** | ✅ **85%** | `QuestRewardsCalculator` (XP, or, bonus timing/streak), intégré à la validation. |
| **Progression joueur** | ✅ **85%** | `PlayerProvider` (niveau, XP, or, HP, moral, streak), stockage Hive. |
| **Page Profil** | ✅ **80%** | `ProfilePage` avec stats (niveau, XP, or, streak, quêtes terminées). |

### 🟡 Importantes - PARTIELLES

| Fonctionnalité | État | Détails |
|----------------|------|---------|
| **Inventaire simple** | ❌ **0%** | **MANQUANT** - Pas de page `InventoryPage`, pas de `InventoryProvider` dans `main.dart`. |
| **Personnalisation avatar** | ❌ **0%** | **MANQUANT** - Pas de page `AvatarPage`, pas de `EquipmentProvider` dans `main.dart`. |

---

## ❌ Ce qui MANQUE (MVP Phase 1)

### 🔴 Critique - À faire en PRIORITÉ

#### 1. **Page Inventaire** (`lib/ui/pages/inventory/inventory_page.dart`)
- **Statut :** Absente
- **Ce qui doit être fait :**
  - Créer `InventoryProvider` (50 slots, stacking)
  - Créer la page avec grille d'items
  - Afficher rareté, nom, description
  - Lier aux récompenses de quêtes (ajout d'items après validation)
- **Impact MVP :** 🔴 **Bloquant** - Les items obtenus ne sont pas visibles/utilisables

#### 2. **Page Personnalisation Avatar** (`lib/ui/pages/avatar/avatar_page.dart`)
- **Statut :** Absente
- **Ce qui doit être fait :**
  - Créer `EquipmentProvider` (6 slots d'équipement)
  - Créer la page avec avatar affiché
  - Interface pour équiper/déséquiper des items
  - Aperçu en temps réel
- **Impact MVP :** 🔴 **Bloquant** - La personnalisation est un pilier du MVP

#### 3. **Hub / Accueil principal**
- **Statut :** Partiel (`app_new.dart` utilise seulement 2 pages)
- **Ce qui doit être fait :**
  - Page Hub avec avatar visible, niveau, XP, accès rapide aux quêtes
  - Navigation complète (Inventaire, Avatar, Profil)
  - Remplacement de la `BottomNavigationBar` simple par une navigation plus riche
- **Impact MVP :** 🟡 **Important** - L'expérience utilisateur est incomplète sans hub central

---

## 🔧 Ce qui doit être MODIFIÉ / AMÉLIORÉ

### Priorité HAUTE

#### 1. **Providers manquants dans `main.dart`**
```dart
// ACTUEL (4 providers)
- ThemeProvider ✅
- AuthProvider ✅
- QuestProvider ✅
- PlayerProvider ✅

// MANQUANT
- InventoryProvider ❌
- EquipmentProvider ❌
```

**Action :** Créer les providers et les enregistrer dans `MultiProvider`.

#### 2. **Boxes Hive manquantes**
```dart
// ACTUEL
await Hive.openBox('quests');
await Hive.openBox('playerStats');
await Hive.openBox('settings');

// MANQUANT
await Hive.openBox('inventory');  // ❌
await Hive.openBox('equipment');  // ❌
```

**Action :** Ajouter l'ouverture des boxes dans `main.dart`.

#### 3. **Navigation incomplète**
- **Actuel :** `app_new.dart` n'a que 2 pages (Quêtes, Profil)
- **Attendu MVP :** Hub, Quêtes, Inventaire, Avatar, Profil, Paramètres
- **Action :** Implémenter la navigation complète avec accès à toutes les pages MVP

#### 4. **Intégration récompenses → Inventaire**
- **Actuel :** Les récompenses calculent XP/or mais n'ajoutent pas d'items à l'inventaire
- **Action :** Après validation d'une quête, ajouter un item aléatoire (probabilité ~20-30%) à l'inventaire via `InventoryProvider`

### Priorité MOYENNE

#### 5. **Onboarding**
- **Statut :** Page existe (`onboarding_page.dart`) mais pas intégrée dans le flux
- **Action :** Vérifier l'intégration dans `app_new.dart` pour les nouveaux utilisateurs

#### 6. **Page Récompenses**
- **Statut :** Existe (`rewards_page.dart`) mais peut-être redondante avec l'animation dans `QuestValidationPage`
- **Action :** Clarifier le rôle ou fusionner avec la validation

---

## 📋 Plan d'action PRIORITAIRE

### Sprint 1 : Compléter le cœur MVP (1-2 semaines)

#### Jour 1-2 : Inventaire
- [ ] Créer `InventoryProvider` avec 50 slots, stacking
- [ ] Créer `lib/ui/pages/inventory/inventory_page.dart` (grille, détails items)
- [ ] Ajouter box Hive `inventory` dans `main.dart`
- [ ] Enregistrer `InventoryProvider` dans `MultiProvider`
- [ ] Intégrer l'ajout d'items après validation de quête (drop aléatoire)

#### Jour 3-4 : Équipement
- [ ] Créer `EquipmentProvider` avec 6 slots
- [ ] Créer `lib/ui/pages/avatar/avatar_page.dart` (affichage avatar, équiper/déséquiper)
- [ ] Ajouter box Hive `equipment` dans `main.dart`
- [ ] Enregistrer `EquipmentProvider` dans `MultiProvider`
- [ ] Lier équipement à l'inventaire (items équipables depuis l'inventaire)

#### Jour 5-7 : Hub et Navigation
- [ ] Créer `lib/ui/pages/home/sanctuary_page.dart` (hub principal avec avatar, stats, accès rapide)
- [ ] Modifier `app_new.dart` pour navigation complète (Hub, Quêtes, Inventaire, Avatar, Profil)
- [ ] Implémenter navigation cohérente (bottom nav ou dock flottant selon design)
- [ ] Tester le flux complet : Hub → Créer quête → Valider → Voir récompense → Inventaire → Équiper

#### Jour 8-10 : Polish et tests
- [ ] Vérifier que tous les items obtenus apparaissent dans l'inventaire
- [ ] Tester l'équipement/déséquipement
- [ ] Vérifier la persistance Hive (relance app)
- [ ] Corriger bugs UX mineurs
- [ ] Tests sur device réel

---

## 📈 Métriques d'avancement par phase MVP

| Phase MVP | Durée estimée | Avancement | Statut |
|-----------|---------------|------------|--------|
| **1. Setup & Architecture** | 1-2 semaines | ✅ **100%** | Terminé |
| **2. Auth & Profil** | 1-2 semaines | ✅ **95%** | Presque terminé |
| **3. Système de quêtes** | 2-3 semaines | ✅ **90%** | Presque terminé |
| **4. Avatar & Inventaire** | 2-3 semaines | ⚠️ **30%** | **EN COURS** |
| **5. Personnalisation** | 1-2 semaines | ❌ **0%** | **À FAIRE** |
| **6. UI/UX & Polish** | 2-3 semaines | 🟡 **60%** | Partiel |
| **7. Tests & Corrections** | 1-2 semaines | 🟡 **40%** | À venir |

**Durée totale estimée restante :** 4-6 semaines pour compléter le MVP

---

## 🎯 Objectifs MVP vs Réalité

### MVP Requis (Phase 1)
```
✅ Authentification
✅ Création de quêtes
✅ Liste des quêtes
✅ Validation de quête
✅ Système de récompenses
✅ Avatar basique
❌ Inventaire simple
❌ Personnalisation basique
✅ Page Profil
```

### État actuel
```
✅ Authentification (100%)
✅ Création de quêtes (95%)
✅ Liste des quêtes (95%)
✅ Validation de quête (90%)
✅ Système de récompenses (85%)
⚠️ Avatar basique (30% - PlayerProvider existe mais pas de page)
❌ Inventaire simple (0%)
❌ Personnalisation basique (0%)
✅ Page Profil (80%)
```

---

## 🚨 Blocages identifiés

1. **Pas de `InventoryProvider`** → Les items obtenus ne peuvent pas être stockés/affichés
2. **Pas de `EquipmentProvider`** → L'équipement ne peut pas être géré
3. **Navigation incomplète** → L'utilisateur ne peut pas accéder à Inventaire/Avatar
4. **Pas de drop d'items** → Les récompenses ne génèrent pas d'items dans l'inventaire

---

## 💡 Recommandations

### Court terme (MVP)
1. **Priorité absolue :** Créer `InventoryProvider` et `InventoryPage`
2. **Priorité absolue :** Créer `EquipmentProvider` et `AvatarPage`
3. **Important :** Compléter la navigation pour accéder à toutes les pages MVP
4. **Important :** Intégrer le drop d'items après validation de quête

### Moyen terme (Post-MVP Phase 1)
1. Améliorer l'affichage de l'avatar (animations, layers)
2. Ajouter plus de variété d'items (catalogue `items` dans Supabase)
3. Système de rareté visuel (bordures, effets glow)
4. Hub immersif avec décor

### Long terme (Phase 2+)
- Marché / Boutique
- Système d'invocation (gacha)
- Mini-jeux
- Social

---

## 📝 Notes techniques

### Architecture actuelle
- ✅ Clean Architecture respectée
- ✅ Provider pour state management
- ✅ Supabase pour auth + quêtes
- ✅ Hive pour données locales (stats, inventaire futur)

### Points d'attention
- Les providers `InventoryProvider` et `EquipmentProvider` sont mentionnés dans `CLAUDE.md` mais n'existent pas encore dans le code
- La navigation dans `app_new.dart` est minimale (2 pages au lieu de 6-8)
- Le design system est riche (41 widgets) mais certaines pages MVP n'existent pas encore

---

**Prochaine étape recommandée :** Commencer par créer `InventoryProvider` et `InventoryPage` pour débloquer la boucle complète MVP.
