# Composants UI - Documentation

## 📦 Composants créés

### 1. FantasyButton
**Fichier** : `lib/widgets/ui/fantasy_button.dart`

**Description** : Bouton stylisé avec support pour icônes Material et assets d'images.

**Propriétés** :
- `label` : Texte du bouton (requis)
- `onPressed` : Callback au clic
- `icon` : Icône Material (optionnel)
- `assetIcon` : Chemin vers une image asset (optionnel)
- `backgroundColor` : Couleur de fond (défaut: `AppColors.primary`)
- `textColor` : Couleur du texte (défaut: blanc)
- `width` : Largeur du bouton (optionnel)
- `height` : Hauteur du bouton (défaut: 50)
- `padding` : Padding personnalisé (optionnel)
- `isOutlined` : Style outlined (défaut: false)
- `isLoading` : Affiche un indicateur de chargement (défaut: false)

**Exemple d'utilisation** :
```dart
FantasyButton(
  label: 'Attaquer',
  assetIcon: 'assets/icons/items/axe.png',
  backgroundColor: AppColors.error,
  onPressed: () {
    // Action
  },
)
```

---

### 2. FantasyBanner
**Fichier** : `lib/widgets/ui/fantasy_banner.dart`

**Description** : Bannière stylisée pour afficher des informations importantes avec support pour icônes et assets.

**Propriétés** :
- `title` : Titre de la bannière (requis)
- `subtitle` : Sous-titre (optionnel)
- `icon` : Icône Material (optionnel)
- `assetIcon` : Chemin vers une image asset (optionnel)
- `backgroundColor` : Couleur de fond (optionnel)
- `borderColor` : Couleur de la bordure (optionnel)
- `action` : Widget d'action (optionnel)
- `onTap` : Callback au clic (optionnel)

**Variantes prédéfinies** :
- `SuccessBanner` : Bannière de succès (vert)
- `WarningBanner` : Bannière d'avertissement (orange)
- `InfoBanner` : Bannière d'information (bleu)

**Exemple d'utilisation** :
```dart
FantasyBanner(
  title: 'Nouvelle quête disponible !',
  subtitle: 'Complétez cette quête pour gagner 100 XP',
  assetIcon: 'assets/icons/items/scroll.png',
  onTap: () {},
)
```

---

### 3. FantasyTitle
**Fichier** : `lib/widgets/ui/fantasy_title.dart`

**Description** : Titre stylisé avec support pour icônes et assets.

**Propriétés** :
- `text` : Texte du titre (requis)
- `icon` : Icône Material (optionnel)
- `assetIcon` : Chemin vers une image asset (optionnel)
- `textStyle` : Style de texte personnalisé (optionnel)
- `iconColor` : Couleur de l'icône (optionnel)
- `iconSize` : Taille de l'icône (défaut: 32)
- `alignment` : Alignement (défaut: `MainAxisAlignment.start`)

**Variante** :
- `SectionTitle` : Titre de section avec sous-titre et action optionnelle

**Exemple d'utilisation** :
```dart
FantasyTitle(
  text: 'Interface UI',
  assetIcon: 'assets/icons/app_icon.png',
  iconSize: 40,
)
```

---

## 🎨 Page de démonstration

**Fichier** : `lib/pages/ui_showcase_page.dart`

Une page complète de démonstration qui montre tous les composants en action avec les assets disponibles.

**Accès** : Route `/ui-showcase` dans l'application

**Contenu** :
- Section Boutons : Différents styles de boutons avec assets
- Section Bannières : Bannières d'information avec assets
- Section Items : Grille d'items avec images
- Section Actions rapides : Boutons d'action avec assets

---

## 📁 Assets utilisés

Les composants utilisent les assets disponibles dans :
- `assets/icons/items/` : Images d'items du jeu (armes, armures, potions, etc.)
- `assets/icons/app_icon.png` : Icône de l'application

**Assets disponibles** :
- Armes : `axe.png`, `bow.png`, `dagger.png`, `hammer.png`, `wand.png`, `woodSword.png`
- Armures : `armor.png`, `helmet.png`, `shield.png`
- Potions : `potionRed.png`, `potionGreen.png`, `potionBlue.png`
- Gemmes : `gemRed.png`, `gemGreen.png`, `gemBlue.png`
- Autres : `coin.png`, `map.png`, `scroll.png`, `heart.png`, etc.

---

## 🚀 Utilisation rapide

### Ajouter un bouton avec asset
```dart
FantasyButton(
  label: 'Utiliser Potion',
  assetIcon: 'assets/icons/items/potionRed.png',
  backgroundColor: AppColors.error,
  onPressed: () {
    // Action
  },
)
```

### Ajouter une bannière avec asset
```dart
FantasyBanner(
  title: 'Nouvelle quête !',
  subtitle: 'Description de la quête',
  assetIcon: 'assets/icons/items/scroll.png',
  onTap: () {},
)
```

### Ajouter un titre avec asset
```dart
FantasyTitle(
  text: 'Mon Titre',
  assetIcon: 'assets/icons/app_icon.png',
)
```

---

## 🎯 Intégration

Tous les composants sont prêts à être utilisés dans n'importe quelle page de l'application. Ils utilisent le thème de l'application (`AppColors`) pour une cohérence visuelle.

**Import** :
```dart
import '../widgets/ui/fantasy_button.dart';
import '../widgets/ui/fantasy_banner.dart';
import '../widgets/ui/fantasy_title.dart';
```

---

## ✨ Fonctionnalités

- ✅ Support pour icônes Material et assets d'images
- ✅ Styles personnalisables (couleurs, tailles, padding)
- ✅ Variantes prédéfinies (Success, Warning, Info)
- ✅ Animations et effets visuels
- ✅ Design cohérent avec le thème de l'application
- ✅ Responsive et adaptatif


