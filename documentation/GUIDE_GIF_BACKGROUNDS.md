# Guide des Backgrounds Animés (GIF) - Sameva

## ✅ OUI, vous pouvez utiliser des GIF en background !

Flutter supporte nativement les GIF animés. Voici comment les utiliser.

## 🎬 Formats Supportés

### 1. **GIF Animé** (Recommandé pour animations simples)
- ✅ Support natif Flutter
- ✅ Facile à créer depuis vos mockups
- ⚠️ Taille de fichier peut être importante
- ⚠️ Performance : peut être lourd pour de gros GIFs

### 2. **Lottie** (Recommandé pour animations complexes)
- ✅ Déjà dans votre projet (`lottie: ^3.1.2`)
- ✅ Taille réduite
- ✅ Performance excellente
- ✅ Animations vectorielles

### 3. **Rive** (Recommandé pour animations interactives)
- ✅ Déjà dans votre projet (`rive: ^0.13.10`)
- ✅ Animations interactives
- ✅ Performance optimale

## 📦 Utilisation d'un GIF

### Méthode 1 : Directement avec Image.asset

```dart
// Dans votre page
Scaffold(
  body: Stack(
    children: [
      // GIF en background
      Positioned.fill(
        child: Image.asset(
          'assets/images/backgrounds/home_background.gif',
          fit: BoxFit.cover,
        ),
      ),
      // Contenu par-dessus
      YourContent(),
    ],
  ),
)
```

### Méthode 2 : Avec le Widget Helper (Recommandé)

```dart
import 'package:sameva/ui/widgets/common/animated_background_gif.dart';

// Dans votre page
Scaffold(
  body: PageAnimatedBackground(
    gifPath: 'assets/images/backgrounds/home_background.gif',
    staticImagePath: 'assets/images/backgrounds/home_background.png', // Fallback
    opacity: 0.9, // Opacité optionnelle
    child: YourContent(),
  ),
)
```

## 🎨 Exemples d'Utilisation

### Background pour SanctuaryPage

```dart
class SanctuaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageAnimatedBackground(
      gifPath: 'assets/images/backgrounds/sanctuary_background.gif',
      staticImagePath: 'assets/images/backgrounds/sanctuary_background.png',
      child: Scaffold(
        // Votre contenu ici
      ),
    );
  }
}
```

### Background avec Opacité

```dart
AnimatedBackgroundGif(
  gifPath: 'assets/images/backgrounds/market_background.gif',
  fit: BoxFit.cover,
  opacity: 0.7, // 70% d'opacité pour laisser voir le contenu
  colorFilter: Colors.blue.withOpacity(0.2), // Filtre de couleur optionnel
)
```

## 📐 Tailles Recommandées pour GIF

| Type | Taille | Poids Max | Durée |
|------|--------|-----------|-------|
| **Background Page** | 1080x1920px | 2-5 MB | 3-10 secondes |
| **Background Petit** | 540x960px | 500KB-1MB | 2-5 secondes |
| **Effet Particules** | 256x256px | 100-500KB | 1-3 secondes |

**⚠️ Important** : Les GIFs peuvent être lourds. Optimisez-les !

## 🚀 Optimisation des GIFs

### 1. Réduire la Taille

**Outils recommandés** :
- **EZGIF** (https://ezgif.com/optimize) - Compression GIF
- **GIFsicle** - Outil en ligne de commande
- **Photoshop** - Export optimisé

**Techniques** :
- Réduire le nombre de couleurs (256 → 128 ou moins)
- Réduire la résolution si possible
- Réduire le nombre de frames
- Utiliser une durée plus courte

### 2. Alternative : Convertir en Lottie

Si votre GIF est trop lourd, convertissez-le en Lottie :

**Outils** :
- **LottieFiles** (https://lottiefiles.com/tools/gif-to-lottie)
- **After Effects** → Bodymovin → Lottie

**Avantages** :
- Taille réduite (souvent 10x plus petit)
- Meilleure performance
- Qualité vectorielle

## 🎯 Alternatives Recommandées

### Option 1 : Lottie (Meilleur pour animations complexes)

```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/background_animation.json',
  fit: BoxFit.cover,
  repeat: true,
)
```

### Option 2 : Animation Programmatique (Déjà dans votre projet)

Votre projet a déjà `AnimatedBackground` qui crée des animations programmatiques :

```dart
import 'package:sameva/ui/widgets/fantasy/animated_background.dart';

AnimatedBackground() // Crée des particules et gradients animés
```

### Option 3 : Rive (Pour animations interactives)

```dart
import 'package:rive/rive.dart';

RiveAnimation.asset(
  'assets/animations/rive/background.riv',
  fit: BoxFit.cover,
)
```

## 📝 Structure Recommandée

```
assets/images/backgrounds/
├── home_background.gif          (GIF animé)
├── home_background.png           (Fallback statique)
├── market_background.gif
├── market_background.png
├── sanctuary_background.gif
└── sanctuary_background.png
```

## 🔧 Configuration dans pubspec.yaml

Assurez-vous que les backgrounds sont déclarés :

```yaml
flutter:
  assets:
    - assets/images/backgrounds/
```

## 💡 Recommandations

### ✅ Utilisez GIF si :
- Animation simple (particules, gradients animés)
- Durée courte (2-5 secondes)
- Taille < 2MB
- Animation en boucle

### ❌ Évitez GIF si :
- Animation complexe (> 5MB)
- Animation longue (> 10 secondes)
- Besoin de performance maximale
- Animation interactive

### 🎯 Alternative Recommandée :
- **Lottie** pour animations complexes
- **Rive** pour animations interactives
- **Animation programmatique** pour effets simples

## 🎨 Exemple Complet

### Créer un Background Animé pour une Page

```dart
import 'package:sameva/ui/widgets/common/animated_background_gif.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PageAnimatedBackground(
      // GIF animé (priorité)
      gifPath: 'assets/images/backgrounds/my_page_background.gif',
      // Image statique (fallback si GIF n'existe pas)
      staticImagePath: 'assets/images/backgrounds/my_page_background.png',
      // Opacité pour laisser voir le contenu
      opacity: 0.8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Votre contenu ici
              Text('Contenu de la page'),
            ],
          ),
        ),
      ),
    );
  }
}
```

## ⚡ Performance

### Optimisations

1. **Cache le GIF** : Flutter le cache automatiquement
2. **Utilisez des GIFs courts** : 2-5 secondes max
3. **Réduisez la résolution** : 1080x1920px max pour mobile
4. **Compressez** : Utilisez EZGIF ou similaire
5. **Considérez Lottie** : Pour de meilleures performances

### Monitoring

Si vous remarquez des ralentissements :
1. Vérifiez la taille du GIF
2. Réduisez la résolution
3. Réduisez le nombre de frames
4. Considérez Lottie comme alternative

## 🎬 Workflow Complet

### Étape 1 : Créer/Exporter le GIF

1. **Depuis vos mockups** :
   - Exportez en GIF animé
   - Ou créez une animation dans After Effects → Export GIF

2. **Optimiser** :
   - Utilisez EZGIF pour compresser
   - Réduisez les couleurs si possible
   - Gardez la durée courte (2-5 secondes)

### Étape 2 : Placer dans le Projet

```
assets/images/backgrounds/home_background.gif
```

### Étape 3 : Utiliser dans le Code

```dart
PageAnimatedBackground(
  gifPath: 'assets/images/backgrounds/home_background.gif',
  child: YourContent(),
)
```

## 📚 Ressources

- **EZGIF** : https://ezgif.com/ (Optimisation GIF)
- **LottieFiles** : https://lottiefiles.com/ (Conversion GIF → Lottie)
- **Flutter Assets** : https://docs.flutter.dev/development/ui/assets-and-images

---

**En résumé** : OUI, vous pouvez utiliser des GIFs ! Mais pour de meilleures performances, considérez Lottie ou Rive pour les animations complexes. 🚀

