# Analyse du Design Figma - MVP Sameva

## 📋 Vue d'ensemble

Ce document analyse le design Figma exporté et propose des modifications pour aligner le projet Flutter avec le design système défini.

## 🎨 Design System Identifié

### Palette de Couleurs

**Couleurs Principales :**
- **Turquoise Primaire** : `#4FD1C5` / `#38B2AC`
- **Violet Secondaire** : `#805AD5` / `#B794F4`
- **Or** : `#F6E05E` / `#D69E2E`
- **Backgrounds** : 
  - Deep Violet : `#2D2B55`
  - Night Blue : `#0F172A`
  - Dark Panel : `#1A202C`

**Système de Rareté :**
- **Common** : `#CBD5E0` (Gris)
- **Uncommon** : `#68D391` (Vert)
- **Rare** : `#4299E1` (Bleu)
- **Epic** : `#9F7AEA` (Violet) + glow
- **Legendary** : `#ECC94B` (Or) + glow pulse
- **Mythic** : `#FC8181` (Rouge) + glow pulse

### Typographie

- **Titres Fantasy** : Cinzel Decorative (serif)
- **Corps de texte** : Nunito (sans-serif)
- **Police rétro** : Press Start 2P (pour éléments gamifiés)

### Effets Visuels

1. **Glassmorphic** : 
   - Background : `rgba(255, 255, 255, 0.1)`
   - Backdrop blur : `20px`
   - Border : `1px solid rgba(255, 255, 255, 0.2)`

2. **Gradients** :
   - Primary : `linear-gradient(135deg, #4FD1C5, #38B2AC)`
   - Gold : `linear-gradient(135deg, #F6E05E, #D69E2E)`
   - Violet : `linear-gradient(135deg, #805AD5, #B794F4)`

3. **Glows** :
   - Purple/Blue glows pour les éléments actifs
   - Pulsing glows pour les raretés épiques

4. **Particules** : Effets de particules magiques en arrière-plan

## 📱 Structure de Navigation

### Pages Principales

1. **Sanctuary** (Accueil)
   - Avatar central avec effets magiques
   - Quêtes actives en carousel
   - Actions rapides
   - Background mystique (forêt)

2. **Quests** (Quêtes)
   - Liste des quêtes avec filtres (Toutes, En cours, Terminées)
   - Barre de progression
   - Badges de difficulté
   - Récompenses affichées

3. **Quest Creation** (Création de quête)
   - Formulaire avec catégories (Étude, Sport, Bien-être, Créativité, Social)
   - Sélection de difficulté (Facile, Moyen, Difficile)
   - Récompenses automatiques selon difficulté

4. **Inventory** (Inventaire)
   - Grille 3 colonnes
   - Filtres par type (Tous, Tenues, Auras, Décors, Familiers)
   - Bordures de rareté
   - Modal de détail d'item

5. **Profile** (Profil)
   - Carte profil avec avatar et niveau
   - Barre d'XP
   - Statistiques (Quêtes complétées, Jours actifs, etc.)
   - Accomplissements
   - Paramètres

6. **Authentication** (Authentification)
   - Design glassmorphic
   - Particules magiques en arrière-plan
   - Toggle Sign Up / Sign In
   - Option Google (future)

### Navigation Bar

5 onglets en bas :
- **Accueil** (Home) → Sanctuary
- **Quêtes** (Scroll) → QuestList
- **Sac** (Package) → Inventory
- **Cercle** (Users) → Social
- **Réglages** (Settings) → Settings

## 🔄 Modifications Proposées pour Flutter

### 1. Mise à jour des Couleurs (`lib/ui/theme/app_colors.dart`)

```dart
class AppColors {
  // Couleurs principales (selon Figma)
  static const Color primaryTurquoise = Color(0xFF4FD1C5);
  static const Color primaryTurquoiseDark = Color(0xFF38B2AC);
  static const Color secondaryViolet = Color(0xFF805AD5);
  static const Color secondaryVioletGlow = Color(0xFFB794F4);
  static const Color gold = Color(0xFFF6E05E);
  static const Color goldDark = Color(0xFFD69E2E);
  
  // Backgrounds
  static const Color backgroundDeepViolet = Color(0xFF2D2B55);
  static const Color backgroundNightBlue = Color(0xFF0F172A);
  static const Color backgroundDarkPanel = Color(0xFF1A202C);
  
  // Système de rareté
  static const Color rarityCommon = Color(0xFFCBD5E0);
  static const Color rarityUncommon = Color(0xFF68D391);
  static const Color rarityRare = Color(0xFF4299E1);
  static const Color rarityEpic = Color(0xFF9F7AEA);
  static const Color rarityLegendary = Color(0xFFECC94B);
  static const Color rarityMythic = Color(0xFFFC8181);
}
```

### 2. Créer un Widget GlassmorphicCard

```dart
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  
  const GlassmorphicCard({required this.child, this.padding});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: child,
        ),
      ),
    );
  }
}
```

### 3. Créer un Widget RarityBorder

```dart
class RarityBorder extends StatelessWidget {
  final ItemRarity rarity;
  final Widget child;
  final bool withGlow;
  
  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(rarity);
    final glow = _shouldGlow(rarity);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: glow ? [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: child,
    );
  }
}
```

### 4. Mettre à jour la Navigation

- Remplacer la navigation actuelle par une barre en bas avec 5 onglets
- Ajouter des animations de transition entre les pages
- Utiliser les icônes appropriées

### 5. Améliorer les Pages

**Page d'accueil (Sanctuary)** :
- Avatar central avec effets magiques
- Carousel de quêtes actives
- Background avec image/gradient mystique

**Page de création de quête** :
- Catégories avec icônes (Étude, Sport, Bien-être, Créativité, Social)
- Sélection de difficulté avec récompenses affichées
- Design glassmorphic

**Page de liste de quêtes** :
- Filtres (Toutes, En cours, Terminées)
- Barres de progression animées
- Badges de difficulté
- Design avec bordures de rareté

**Page d'inventaire** :
- Grille 3 colonnes
- Filtres horizontaux scrollables
- Bordures de rareté sur les items
- Modal de détail

## 📝 Prochaines Étapes

1. ✅ Mettre à jour `app_colors.dart` avec les couleurs Figma
2. ✅ Créer `GlassmorphicCard` widget
3. ✅ Créer `RarityBorder` widget
4. ✅ Mettre à jour la navigation avec 5 onglets
5. ✅ Améliorer la page d'accueil (Sanctuary)
6. ✅ Améliorer la page de création de quête
7. ✅ Améliorer la page de liste de quêtes
8. ✅ Améliorer la page d'inventaire
9. ✅ Ajouter des animations fluides
10. ✅ Ajouter des effets de particules/glow

