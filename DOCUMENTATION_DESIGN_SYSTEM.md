# Documentation - Design System

## 🎨 Vue d'ensemble

Le Design System de Sameva définit tous les éléments visuels, composants UI, couleurs, typographies et animations utilisés dans l'application pour assurer une expérience cohérente et professionnelle.

---

## 🎨 Palette de Couleurs

### Couleurs Principales

**Fichier** : `lib/theme/app_colors.dart`

#### Couleurs de Base

- **Primary** : `#785096` (Violet)
  - Utilisation : Boutons principaux, accents
  - RGB : `rgb(120, 80, 150)`

- **Primary Foreground** : `#FAF8FC` (Blanc cassé)
  - Utilisation : Texte sur fond primary

- **Secondary** : `#DCD2EB` (Violet clair)
  - Utilisation : Bordures, séparateurs

- **Accent** : `#C8B4DC` (Violet moyen)
  - Utilisation : Accents, hover states

- **Accent Foreground** : `#3C2850` (Violet foncé)
  - Utilisation : Texte sur fond accent

#### Couleurs de Fond

- **Background** : `#F5F0F5` (Beige clair)
  - Utilisation : Fond principal (thème clair)

- **Background Dark** : `#2A2438` (Violet foncé)
  - Utilisation : Fond principal (thème sombre)

- **Card** : `#FAF8FC` (Blanc cassé)
  - Utilisation : Fond des cartes

- **Card Foreground** : `#3C2850` (Violet foncé)
  - Utilisation : Texte sur cartes

#### Couleurs de Texte

- **Text Primary** : `#3C2850` (Violet foncé)
  - Utilisation : Texte principal

- **Text Secondary** : `#78648C` (Violet moyen)
  - Utilisation : Texte secondaire

- **Text Muted** : `#E6DCF0` (Violet très clair)
  - Utilisation : Texte désactivé

#### Couleurs de Bordure

- **Border** : `#DCD2EB` (Violet clair)
  - Utilisation : Bordures générales

- **Input** : `#DCD2EB` (Violet clair)
  - Utilisation : Bordures des inputs

#### Couleurs d'État

- **Success** : `#4CAF50` (Vert)
  - Utilisation : Succès, confirmations

- **Info** : `#2196F3` (Bleu)
  - Utilisation : Informations

- **Warning** : `#FF9800` (Orange)
  - Utilisation : Avertissements

- **Error** : `#B00020` (Rouge)
  - Utilisation : Erreurs

### Couleurs de Rareté

Utilisées pour les quêtes et items :

1. **Commun** : `#9E9E9E` (Gris)
2. **Peu Commun** : `#4CAF50` (Vert)
3. **Rare** : `#2196F3` (Bleu)
4. **Très Rare** : `#9C27B0` (Violet)
5. **Épique** : `#FF9800` (Orange)
6. **Légendaire** : `#FFD700` (Or)
7. **Mythique** : `#FF1744` (Rouge)

---

## 📝 Typographie

### Polices

**Fichier** : `pubspec.yaml`

#### Police Principale
- **Poppins** (via Google Fonts)
  - Utilisation : Texte général
  - Poids : 400 (regular), 600 (semi-bold), 700 (bold)

#### Polices Fantasy
- **MedievalSharp** : `assets/fonts/MedievalSharp-Regular.ttf`
  - Utilisation : Titres spéciaux, éléments fantasy

- **Press Start 2P** : `assets/fonts/press_start_2p.ttf`
  - Utilisation : Éléments gamifiés, scores

### Hiérarchie Typographique

- **Headline Large** : 32px, Bold
  - Utilisation : Titres de page

- **Headline Medium** : 24px, Semi-bold
  - Utilisation : Sous-titres

- **Title Large** : 20px, Semi-bold
  - Utilisation : Titres de sections

- **Title Medium** : 18px, Semi-bold
  - Utilisation : Titres de cartes

- **Body Large** : 16px, Regular
  - Utilisation : Texte principal

- **Body Medium** : 14px, Regular
  - Utilisation : Texte secondaire

- **Body Small** : 12px, Regular
  - Utilisation : Texte auxiliaire

- **Label** : 14px, Semi-bold
  - Utilisation : Labels, boutons

---

## 🧩 Composants UI

### 1. FantasyCard

**Fichier** : `lib/widgets/figma/fantasy_card.dart`

#### Description
Carte avec style fantasy, bordures arrondies et ombres.

#### Propriétés
- `child` : Contenu principal
- `header` : En-tête personnalisé
- `footer` : Pied de page
- `title` : Titre de la carte
- `description` : Description
- `action` : Action (bouton, etc.)
- `padding` : Padding personnalisé
- `backgroundColor` : Couleur de fond
- `border` : Bordure personnalisée
- `boxShadow` : Ombres personnalisées
- `margin` : Marge externe

#### Utilisation
```dart
FantasyCard(
  title: 'Ma Quête',
  description: 'Description de la quête',
  child: Text('Contenu'),
)
```

#### Design
- **Border Radius** : 16px
- **Padding** : 24px (par défaut)
- **Ombre** : Légère ombre portée
- **Bordure** : 1px, couleur `AppColors.border`

---

### 2. FantasyButton

**Fichier** : `lib/widgets/fantasy/fantasy_button.dart`

#### Description
Bouton avec effet de glow et style fantasy.

#### Propriétés
- `label` : Texte du bouton
- `icon` : Icône (optionnel)
- `onPressed` : Callback
- `glowColor` : Couleur du glow
- `backgroundColor` : Couleur de fond
- `disabled` : État désactivé

#### Utilisation
```dart
FantasyButton(
  label: 'Créer une quête',
  icon: Icons.add,
  glowColor: AppColors.primary,
  onPressed: () {},
)
```

#### Design
- **Border Radius** : 12px
- **Padding** : 16px horizontal, 12px vertical
- **Glow** : Effet de lueur autour du bouton
- **Animation** : Hover effect

---

### 3. FantasyBadge

**Fichier** : `lib/widgets/figma/fantasy_badge.dart`

#### Description
Badge pour afficher des statuts, raretés, etc.

#### Propriétés
- `label` : Texte du badge
- `variant` : Style (default, secondary, outline)
- `color` : Couleur personnalisée
- `padding` : Padding personnalisé

#### Variants
- **default** : Fond coloré, texte blanc
- **secondary** : Fond clair, texte coloré
- **outline** : Bordure, fond transparent

#### Utilisation
```dart
FantasyBadge(
  label: 'Rare',
  variant: BadgeVariant.default_,
)
```

#### Design
- **Border Radius** : 8px
- **Padding** : 8px horizontal, 4px vertical
- **Font Size** : 12px

---

### 4. FantasyAvatar

**Fichier** : `lib/widgets/figma/fantasy_avatar.dart`

#### Description
Avatar avec image ou initiales de fallback.

#### Propriétés
- `imageUrl` : URL de l'image
- `size` : Taille (diamètre)
- `fallbackText` : Texte de fallback
- `borderColor` : Couleur de bordure

#### Utilisation
```dart
FantasyAvatar(
  imageUrl: 'assets/images/avatars/hero.png',
  size: 120,
  fallbackText: 'H',
)
```

#### Design
- **Shape** : Cercle
- **Border** : 2px (optionnel)
- **Fallback** : Initiales sur fond coloré

---

### 5. FantasyBanner

**Fichier** : `lib/widgets/ui/fantasy_banner.dart`

#### Description
Bannière pour promotions, annonces, etc.

#### Propriétés
- `title` : Titre
- `description` : Description
- `imageUrl` : Image de fond (optionnel)
- `action` : Bouton d'action
- `variant` : Style (info, success, warning, error)

#### Utilisation
```dart
FantasyBanner(
  title: 'Nouvelle fonctionnalité !',
  description: 'Découvrez les mini-jeux',
  variant: BannerVariant.info,
)
```

#### Design
- **Border Radius** : 12px
- **Padding** : 16px
- **Gradient** : Selon le variant

---

### 6. FantasyTitle

**Fichier** : `lib/widgets/ui/fantasy_title.dart`

#### Description
Titre stylisé avec effets visuels.

#### Propriétés
- `text` : Texte du titre
- `variant` : Style (h1, h2, h3)
- `color` : Couleur personnalisée
- `glow` : Effet de glow (optionnel)

#### Utilisation
```dart
FantasyTitle(
  text: 'Sameva',
  variant: TitleVariant.h1,
  glow: true,
)
```

#### Design
- **Font** : MedievalSharp ou Poppins Bold
- **Size** : Selon le variant
- **Glow** : Effet de lueur subtil

---

## 🎭 Animations

### Transitions de Page

**Fichier** : `lib/widgets/transitions/custom_transitions.dart`

#### Types
- **Fade** : Fondu
- **Slide** : Glissement
- **Scale** : Zoom
- **Combined** : Fade + Slide

#### Utilisation
```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  },
)
```

### Animations Lottie

**Fichier** : `lib/widgets/animations/`

- **InvocationAnimation** : Animation d'invocation
- **LevelUpAnimation** : Animation de montée de niveau
- **AvatarIdleAnimation** : Animation d'avatar au repos
- **ParticlesHalo** : Particules autour d'éléments
- **FlameParticles** : Particules de feu

---

## 📐 Espacements

### Système de Spacing

- **XS** : 4px
- **S** : 8px
- **M** : 16px
- **L** : 24px
- **XL** : 32px
- **XXL** : 48px

### Utilisation
```dart
const SizedBox(height: 16), // M
const EdgeInsets.all(16),   // M
const EdgeInsets.symmetric(horizontal: 24), // L
```

---

## 🎯 Principes de Design

### 1. Cohérence
- Même style sur toutes les pages
- Composants réutilisables
- Palette de couleurs uniforme

### 2. Hiérarchie
- Titres clairs et visibles
- Contraste suffisant
- Espacement approprié

### 3. Feedback
- Animations pour les actions
- États de chargement
- Messages d'erreur clairs

### 4. Accessibilité
- Contraste WCAG AA
- Tailles de texte lisibles
- Zones de tap suffisantes (min 44x44px)

### 5. Performance
- Animations fluides (60fps)
- Images optimisées
- Lazy loading

---

## 📱 Responsive Design

### Breakpoints

- **Mobile** : < 600px
  - 1 colonne
  - Padding réduit
  - Textes ajustés

- **Tablette** : 600-900px
  - 2 colonnes
  - Padding moyen

- **Desktop** : > 900px
  - 3+ colonnes
  - Padding large

### Adaptation

- **Grilles** : `GridView` avec `crossAxisCount` adaptatif
- **Textes** : Tailles responsives
- **Images** : `fit: BoxFit.contain`

---

## 🎨 Thèmes

### Thème Clair

- **Background** : `AppColors.background`
- **Text** : `AppColors.textPrimary`
- **Cards** : `AppColors.card`

### Thème Sombre

- **Background** : `AppColors.backgroundDark`
- **Text** : Blanc
- **Cards** : `AppColors.card` avec opacité

### Gestion

**Fichier** : `lib/core/providers/theme_provider.dart`

- Toggle clair/sombre
- Sauvegarde de la préférence
- Application globale

---

## 🖼️ Assets

### Images

- **Format** : PNG, JPG
- **Taille recommandée** : 256x256px minimum
- **Optimisation** : Compression pour performance

### Icônes

- **Format** : PNG, SVG
- **Taille** : 24x24px, 32x32px, 48x48px
- **Style** : Material Design Icons

### Animations

- **Lottie** : `.json` files
- **Rive** : `.riv` files
- **Taille** : Optimisée

---

## 📝 Guidelines

### Utilisation des Couleurs

- **Primary** : Actions principales uniquement
- **Secondary** : Actions secondaires
- **Rareté** : Uniquement pour items/quêtes
- **État** : Selon le contexte (succès, erreur, etc.)

### Utilisation des Composants

- **FantasyCard** : Pour tous les contenus en carte
- **FantasyButton** : Pour les actions principales
- **FantasyBadge** : Pour les statuts et raretés
- **FantasyAvatar** : Pour tous les avatars

### Animations

- **Durée** : 200-300ms pour les transitions
- **Courbe** : `Curves.easeOutCubic` par défaut
- **Performance** : Éviter les animations lourdes

---

## 🔗 Références

- [Material Design](https://material.io/design)
- [Flutter Design](https://flutter.dev/docs/development/ui/widgets)
- [Figma Components](./assets/components/)

