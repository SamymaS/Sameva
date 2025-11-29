# Documentation - Navigation et Routes

## 🧭 Vue d'ensemble

La navigation de Sameva est organisée autour d'une barre de navigation principale avec 5 onglets, complétée par des routes nommées pour accéder aux pages secondaires.

---

## 📱 Navigation Principale

### Barre de Navigation Inférieure

**Fichier** : `lib/app_new.dart`

#### Structure

La barre de navigation contient **5 destinations principales** :

1. 🏠 **Accueil** (`NewHomePage`)
   - Icône : `Icons.home`
   - Label : "Accueil"
   - Index : 0

2. 🛒 **Marché** (`MarketPage`)
   - Icône : `Icons.store`
   - Label : "Marché"
   - Index : 1

3. ✨ **Invocation** (`InvocationPage`)
   - Icône : `Icons.auto_awesome`
   - Label : "Invocation"
   - Index : 2

4. 👤 **Avatar** (`AvatarPage`)
   - Icône : `Icons.face_retouching_natural`
   - Label : "Avatar"
   - Index : 3

5. 🎮 **Mini-Jeux** (`MiniGamePage`)
   - Icône : `Icons.sports_esports`
   - Label : "Mini-Jeux"
   - Index : 4

#### Design

- **Fond** : `Color(0xFF111624)` (Sombre)
- **Indicateur** : `Color(0x33569CF6)` (Bleu avec opacité)
- **Icônes** : Material Design Icons
- **Labels** : Sous les icônes
- **Hauteur** : Adaptative selon le contenu

#### Fonctionnalités

- **Sélection** : Tap sur une destination
- **Animation** : Transition fluide entre pages
- **État** : Conservation de l'état de chaque page
- **Indicateur** : Mise en surbrillance de la page active

#### Code

```dart
NavigationBar(
  backgroundColor: const Color(0xFF111624),
  indicatorColor: const Color(0x33569CF6),
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
    NavigationDestination(icon: Icon(Icons.store), label: 'Marché'),
    NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Invocation'),
    NavigationDestination(icon: Icon(Icons.face_retouching_natural), label: 'Avatar'),
    NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Mini-Jeux'),
  ],
)
```

---

## 🔄 Transitions entre Pages

### AnimatedSwitcher

**Fichier** : `lib/app_new.dart`

#### Configuration

- **Durée** : 300ms
- **Courbe entrée** : `Curves.easeOutCubic`
- **Courbe sortie** : `Curves.easeInCubic`
- **Type** : Fade + Slide

#### Code

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  transitionBuilder: (child, animation) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  },
  child: KeyedSubtree(
    key: ValueKey<int>(index),
    child: pages[index],
  ),
)
```

---

## 🛣️ Routes Nommées

### Configuration

**Fichier** : `lib/app_new.dart`

#### Routes Disponibles

```dart
routes: {
  '/profile': (context) => const ProfilePage(),
  '/settings': (context) => const SettingsPage(),
  '/quests': (context) => const QuestsListPage(),
  '/ui-showcase': (context) => const UIShowcasePage(),
  '/inventory': (context) => const InventoryPage(),
}
```

### Utilisation

#### Navigation vers une Route

```dart
Navigator.of(context).pushNamed('/profile');
```

#### Navigation avec Retour

```dart
Navigator.of(context).pushNamed('/settings');
```

#### Navigation avec Remplacement

```dart
Navigator.of(context).pushReplacementNamed('/profile');
```

#### Navigation avec Suppression de l'Historique

```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  '/profile',
  (route) => false,
);
```

---

## 📄 Pages et Routes

### Pages Principales (Navigation Bar)

| Index | Page | Widget | Route |
|-------|------|--------|-------|
| 0 | Accueil | `NewHomePage` | - |
| 1 | Marché | `MarketPage` | - |
| 2 | Invocation | `InvocationPage` | - |
| 3 | Avatar | `AvatarPage` | - |
| 4 | Mini-Jeux | `MiniGamePage` | - |

### Pages Secondaires (Routes)

| Route | Page | Widget | Accès |
|-------|------|--------|-------|
| `/profile` | Profil | `ProfilePage` | Depuis accueil, paramètres |
| `/settings` | Paramètres | `SettingsPage` | Depuis accueil, profil |
| `/quests` | Liste des Quêtes | `QuestsListPage` | Depuis accueil |
| `/inventory` | Inventaire | `InventoryPage` | Depuis accueil, avatar |
| `/ui-showcase` | Showcase UI | `UIShowcasePage` | Développement uniquement |

### Pages de Navigation Directe

| Page | Widget | Navigation |
|------|--------|------------|
| Détails de Quête | `QuestDetailPage` | `MaterialPageRoute` |
| Création de Quête | `FantasyCreateQuestPage` | `MaterialPageRoute` |
| Mini-Jeux individuels | `PlatformerGame`, etc. | `MaterialPageRoute` |

---

## 🔐 Flux d'Authentification

### Pages d'Auth

| Page | Widget | Route | Navigation |
|------|--------|-------|------------|
| Splash | `SplashScreen` | `/` | Automatique |
| Loading | `LoadingScreen` | - | Automatique |
| Login | `LoginPage` | `/login` | Depuis splash/loading |
| Register | `RegisterPage` | `/register` | Depuis login |
| Onboarding | `OnboardingPage` | `/onboarding` | Après inscription |

### Flux

```
Splash → Loading → 
  ├─ Non connecté → Login → Register → Onboarding → Home
  ├─ Connecté + Onboarding → Home
  └─ Connecté + Pas onboarding → Onboarding → Home
```

---

## 🎯 Navigation Contextuelle

### Depuis la Page d'Accueil

- **Bouton Profil** → `/profile`
- **Bouton Paramètres** → `/settings`
- **Bouton "Créer une quête"** → `FantasyCreateQuestPage`
- **Bouton "Voir tout"** (quêtes) → `/quests`
- **Tap sur une quête** → `QuestDetailPage`
- **Bouton "Inventaire"** → `/inventory`

### Depuis la Page Marché

- **Tap sur un item** → Modal de détails
- **Bouton "Acheter"** → Action (pas de navigation)

### Depuis la Page Invocation

- **Tap sur un type d'invocation** → Animation (pas de navigation)
- **Après invocation** → Retour à la page

### Depuis la Page Avatar

- **Tap sur un item** → Équipement (pas de navigation)
- **Bouton "Inventaire"** → `/inventory`

### Depuis la Page Mini-Jeux

- **Tap sur un jeu** → Page du jeu (`MaterialPageRoute`)
- **Bouton retour** → Retour à la liste

---

## 🔙 Gestion du Retour

### AppBar Standard

```dart
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.of(context).pop(),
  ),
  title: const Text('Titre'),
)
```

### Bouton Retour Personnalisé

```dart
IconButton(
  icon: const Icon(Icons.close),
  onPressed: () => Navigator.of(context).pop(),
)
```

### WillPopScope (Déprécié) / PopScope

```dart
PopScope(
  canPop: false,
  onPopInvoked: (didPop) {
    if (!didPop) {
      // Action personnalisée
      Navigator.of(context).pop();
    }
  },
  child: Scaffold(...),
)
```

---

## 🎨 Transitions Personnalisées

### PageRouteBuilder

**Fichier** : `lib/widgets/transitions/custom_transitions.dart`

#### Fade Transition

```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
)
```

#### Slide Transition

```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  },
)
```

#### Combined Transition

```dart
PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
)
```

---

## 📊 État de Navigation

### Conservation de l'État

Les pages de la navigation principale conservent leur état grâce à `KeyedSubtree` :

```dart
KeyedSubtree(
  key: ValueKey<int>(index),
  child: pages[index],
)
```

### Réinitialisation

Pour réinitialiser l'état d'une page, changer la clé :

```dart
KeyedSubtree(
  key: ValueKey('${index}_${timestamp}'),
  child: pages[index],
)
```

---

## 🐛 Gestion des Erreurs

### Navigation Impossible

```dart
try {
  Navigator.of(context).pushNamed('/route');
} catch (e) {
  // Gérer l'erreur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Navigation impossible')),
  );
}
```

### Route Inexistante

```dart
onUnknownRoute: (settings) {
  return MaterialPageRoute(
    builder: (_) => const NotFoundPage(),
  );
}
```

---

## 📝 Bonnes Pratiques

### 1. Utilisation des Routes

- **Routes nommées** : Pour les pages accessibles depuis plusieurs endroits
- **MaterialPageRoute** : Pour les pages contextuelles
- **PageRouteBuilder** : Pour les transitions personnalisées

### 2. Navigation Conditionnelle

```dart
if (condition) {
  Navigator.of(context).pushNamed('/route');
} else {
  // Afficher un message
}
```

### 3. Retour avec Résultat

```dart
// Navigation
final result = await Navigator.of(context).pushNamed('/route');

// Retour
Navigator.of(context).pop('result');
```

### 4. Deep Linking (Futur)

```dart
onGenerateRoute: (settings) {
  // Gérer les deep links
  if (settings.name?.startsWith('/quest/') ?? false) {
    final questId = settings.name!.split('/').last;
    return MaterialPageRoute(
      builder: (_) => QuestDetailPage(questId: questId),
    );
  }
}
```

---

## 🔗 Liens Utiles

- [Flutter Navigation](https://flutter.dev/docs/development/ui/navigation)
- [Material Design Navigation](https://material.io/design/navigation)


