# 🎨 Interface "Moderne Éthérée" - Guide Complet

## 📋 Vue d'Ensemble

L'interface "Moderne Éthérée" remplace le style "pierre lourde" par une approche légère et flottante, optimisée pour une utilisation quotidienne tout en gardant l'aspect magique.

---

## 🎯 Principes de Design

### 1. Légèreté et Flottement
- **Éléments flottants** : Tous les éléments UI flottent par-dessus le monde magique
- **Pas de fonds lourds** : Utilisation de glassmorphism translucide
- **Ombres diffuses** : Créent une impression de lévitation

### 2. Hiérarchie Visuelle
```
Couche 0 : Fond (Image de forêt + overlay sombre)
Couche 1 : Avatar (Centré en haut, fixe)
Couche 2 : Header HUD (Flottant en haut)
Couche 3 : Panneau de Quêtes (Glissant, DraggableScrollableSheet)
Couche 4 : Dock Flottant (Positionné par-dessus tout)
```

### 3. Interaction Progressive
- **État initial** : Avatar visible, 2-3 quêtes en bas
- **Scroll vers le haut** : Panneau monte, avatar disparaît progressivement
- **Focus sur les tâches** : Interface se transforme en mode productivité

---

## 🧩 Composants Créés

### 1. FloatingDock (`lib/ui/widgets/minimalist/floating_dock.dart`)

**Description :** Dock flottant avec glassmorphism pour la navigation.

**Caractéristiques :**
- Capsule allongée horizontale
- Détachée des bords (marges 16px/20px)
- Fond bleu nuit à 85% d'opacité
- Flou d'arrière-plan (BackdropFilter 10px)
- Bordure fine avec dégradé subtil
- Ombre diffuse cyan pour lévitation

**Utilisation :**
```dart
FloatingDock(
  currentIndex: _currentIndex,
  onItemSelected: (index) => setState(() => _currentIndex = index),
  centerFab: FloatingFAB(...),
)
```

### 2. HUDHeader (`lib/ui/widgets/minimalist/hud_header.dart`)

**Description :** Header HUD minimaliste avec barres de santé/XP et ressources.

**Caractéristiques :**
- Pas de fond solide
- Barres fines (4px) pour PV et XP
- Chips translucides pour Or/Cristaux
- Bouton paramètres discret

**Utilisation :**
```dart
HUDHeader(
  level: 14,
  experience: 500,
  maxExperience: 1000,
  healthPoints: 75,
  maxHealthPoints: 100,
  gold: 1500,
  crystals: 50,
)
```

### 3. FloatingFAB (`lib/ui/widgets/minimalist/floating_fab.dart`)

**Description :** FAB central flottant avec animation de respiration.

**Caractéristiques :**
- Sphère parfaite 56x56px
- Dégradé radial or doux (#F59E0B)
- Animation de respiration (scale 1.0 → 1.05)
- Ombre diffuse pour lévitation

**Utilisation :**
```dart
FloatingFAB(
  icon: Icons.add,
  onPressed: () => {},
  tooltip: 'Nouvelle Quête',
)
```

### 4. QuestCardMinimalist (`lib/ui/widgets/minimalist/quest_card_minimalist.dart`)

**Description :** Carte de quête pour le panneau glissant.

**Caractéristiques :**
- Hauteur fixe 80px
- Fond très sombre (white.withOpacity(0.05))
- Bordure gauche colorée (difficulté)
- Rune de validation (checkbox) à droite

**Utilisation :**
```dart
QuestCardMinimalist(
  quest: quest,
  onTap: () => {},
  onComplete: () => {},
)
```

---

## 📱 Structure de la Page Sanctuary

### Layout en Couches

```dart
Stack(
  children: [
    // Couche 0 : Fond
    _buildBackground(),
    
    // Couche 1 : Avatar (Positionné)
    _buildHeroAvatar(),
    
    // Couche 2 : Header HUD
    HUDHeader(...),
    
    // Couche 3 : Panneau Glissant
    DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(...),
          child: ListView.builder(
            controller: scrollController,
            itemBuilder: (context, index) {
              return QuestCardMinimalist(...);
            },
          ),
        );
      },
    ),
  ],
)
```

### DraggableScrollableSheet

**Avantages :**
- ✅ Interaction naturelle (glisser vers le haut)
- ✅ Transition fluide entre vue immersive et vue productivité
- ✅ Handle visible pour indiquer l'interaction
- ✅ Dégradé vertical pour transition douce

**Paramètres :**
- `initialChildSize: 0.45` : Prend 45% de l'écran au début
- `minChildSize: 0.45` : Ne peut pas descendre en dessous
- `maxChildSize: 0.85` : Peut monter jusqu'en haut (sous le header)

---

## 🎨 Spécifications Visuelles

### Dock Flottant

**Dimensions :**
- Hauteur : 70px
- Marges : 16px (côtés), 20px (bas)
- Rayon de bordure : 30px (capsule)

**Couleurs :**
- Fond : `#0B0F18` à 85% d'opacité
- Bordure : Blanc à 10% d'opacité
- Ombre : Cyan à 20% d'opacité, blur 20px

**États des Icônes :**
- Inactif : Blanc à 50% d'opacité
- Actif : Blanc pur + point lumineux cyan (4px) avec glow

### Header HUD

**Barres de Progression :**
- Hauteur : 4px
- Rayon : 2px
- Gradient : Couleur pleine → Couleur à 70% d'opacité

**Chips de Ressources :**
- Fond : Noir à 30% d'opacité
- Bordure : Blanc à 10% d'opacité
- Rayon : 16px
- Padding : 10px horizontal, 6px vertical

### FAB Central

**Dimensions :**
- Taille : 56x56px
- Position : Centré horizontalement, 45px du bas

**Couleurs :**
- Dégradé radial : Or (#F59E0B) → Or 70% → Jaune pâle (#FFF8DC)
- Ombres : 2 ombres (une proche, une diffuse)

**Animation :**
- Durée : 2 secondes
- Scale : 1.0 → 1.05
- Répétition : Reverse (infini)

### Cartes de Quêtes

**Dimensions :**
- Hauteur : 80px (fixe)
- Rayon : 16px
- Bordure gauche : 3px (couleur selon difficulté)

**Couleurs :**
- Fond : Blanc à 5% d'opacité
- Texte : Blanc (titre), Blanc 60% (sous-titre)

**Rune de Validation :**
- Taille : 32x32px
- Bordure : Blanc à 30% d'opacité, 2px
- État complété : Icône check cyan

---

## 🔄 Flux Utilisateur

### 1. Ouverture de l'App
1. Utilisateur voit l'avatar dans la forêt (immersion)
2. Header HUD visible en haut (stats)
3. Panneau de quêtes montre 2-3 quêtes en bas
4. Dock flottant visible en bas

### 2. Interaction avec les Quêtes
1. Utilisateur scroll vers le haut
2. Panneau monte progressivement
3. Avatar disparaît doucement (fond flouté)
4. Liste complète des quêtes visible
5. Mode productivité activé

### 3. Navigation
1. Utilisateur clique sur une icône du dock
2. Transition fade + slide vers la nouvelle page
3. Dock reste visible (toujours flottant)
4. FAB central reste au centre

---

## 📐 Implémentation Technique

### Stack Structure
```dart
Stack(
  children: [
    // Fond
    Container(...),
    
    // Avatar (Positionné)
    Positioned(
      top: 120,
      child: Avatar(),
    ),
    
    // Header (SafeArea)
    SafeArea(child: HUDHeader()),
    
    // Panneau Glissant
    DraggableScrollableSheet(...),
    
    // Dock (Positionné en bas)
    Positioned(
      bottom: 20,
      child: FloatingDock(),
    ),
  ],
)
```

### Gestion du Scroll
Le `scrollController` du `DraggableScrollableSheet` doit être lié au `ListView.builder` pour que le scroll fonctionne correctement.

### Performance
- Utiliser `const` constructors quand possible
- Limiter les rebuilds avec `Consumer` ciblé
- Animations optimisées avec `SingleTickerProviderStateMixin`

---

## ✅ Checklist d'Implémentation

- [x] FloatingDock créé
- [x] HUDHeader créé
- [x] FloatingFAB créé
- [x] QuestCardMinimalist créé
- [x] SanctuaryPage refactorisée avec DraggableScrollableSheet
- [x] app_new.dart mis à jour avec FloatingDock
- [ ] Tester les transitions entre pages
- [ ] Ajuster les positions et tailles
- [ ] Ajouter des micro-interactions supplémentaires
- [ ] Optimiser les performances

---

## 🎯 Résultat Attendu

Une interface qui :
- ✅ **Flotte** : Tous les éléments semblent léviter
- ✅ **S'adapte** : Passage fluide entre immersion et productivité
- ✅ **Guide** : L'utilisateur sait toujours où se trouve l'action principale
- ✅ **Reste magique** : Garde l'identité RPG tout en étant moderne






