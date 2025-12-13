# Documentation - Authentification et Onboarding

## 🔐 Vue d'ensemble

Le système d'authentification de Sameva gère la connexion, l'inscription et l'expérience de première utilisation des utilisateurs. Il utilise Firebase Authentication pour la gestion des comptes.

---

## 📱 Pages d'Authentification

### 1. Splash Screen

**Fichier** : `lib/pages/splash/splash_screen.dart`

**Description** :
Écran de démarrage affiché au lancement de l'application. Affiche le logo Sameva avec une animation.

**Fonctionnalités** :
- Animation d'apparition du logo
- Délai de 2-3 secondes
- Redirection automatique vers :
  - Page de connexion si non connecté
  - Page d'onboarding si première utilisation
  - Page d'accueil si déjà connecté

**Design** :
- Fond sombre (`AppColors.backgroundDark`)
- Logo centré avec animation de fade-in
- Couleur d'accent : Violet/Or

**Flux** :
```
Splash Screen → Vérification Auth → Login/Onboarding/Home
```

---

### 2. Page de Connexion

**Fichier** : `lib/pages/auth/login_page.dart`

**Description** :
Page principale pour se connecter à l'application.

**Éléments UI** :
- **Titre** : "Connexion" ou "Bienvenue sur Sameva"
- **Champ Email** : Input avec validation
- **Champ Mot de passe** : Input avec masquage/affichage
- **Bouton Connexion** : Bouton principal avec loading state
- **Lien Inscription** : "Pas encore de compte ? S'inscrire"
- **Mode Test** : Bypass pour développement (peut être désactivé)

**Fonctionnalités** :
- Validation des champs (email valide, mot de passe non vide)
- Connexion via Firebase Auth
- Gestion des erreurs (affichage de messages)
- Mode test : Bypass avec identifiants par défaut
- Navigation vers l'inscription
- Redirection après connexion réussie

**Design** :
- Fond avec gradient ou image de fond
- Formulaire centré dans une carte (`FantasyCard`)
- Boutons avec style fantasy
- Couleurs : Violet primary, blanc pour le texte

**États** :
- **Initial** : Champs vides, bouton actif
- **Loading** : Bouton désactivé, indicateur de chargement
- **Erreur** : Message d'erreur affiché sous le formulaire
- **Succès** : Redirection automatique

**Code d'exemple** :
```dart
// Connexion avec email/password
await context.read<AuthProvider>().signInWithEmailAndPassword(
  email,
  password,
);
```

---

### 3. Page d'Inscription

**Fichier** : `lib/pages/auth/register_page.dart`

**Description** :
Page pour créer un nouveau compte utilisateur.

**Éléments UI** :
- **Titre** : "Créer un compte"
- **Champ Nom** : Nom d'utilisateur (optionnel)
- **Champ Email** : Email pour le compte
- **Champ Mot de passe** : Mot de passe (minimum 6 caractères)
- **Champ Confirmation** : Confirmation du mot de passe
- **Bouton Inscription** : Bouton principal
- **Lien Connexion** : "Déjà un compte ? Se connecter"
- **Conditions d'utilisation** : Checkbox (optionnel)

**Fonctionnalités** :
- Validation des champs :
  - Email valide
  - Mot de passe fort (min 6 caractères)
  - Confirmation identique au mot de passe
- Création de compte via Firebase Auth
- Création du profil utilisateur initial dans Firestore
- Initialisation des statistiques du joueur (niveau 1, 100 PV, 0 or)
- Gestion des erreurs (email déjà utilisé, etc.)
- Navigation vers la connexion
- Redirection vers onboarding après inscription

**Design** :
- Similaire à la page de connexion
- Formulaire plus long avec champs supplémentaires
- Validation en temps réel (optionnel)

**États** :
- **Initial** : Tous les champs vides
- **Validation** : Messages d'erreur sous chaque champ
- **Loading** : Bouton désactivé, indicateur
- **Erreur** : Message d'erreur global
- **Succès** : Redirection vers onboarding

---

### 4. Page d'Onboarding

**Fichier** : `lib/pages/onboarding/onboarding_page.dart`

**Description** :
Page d'introduction pour les nouveaux utilisateurs. Présente les fonctionnalités principales de l'application.

**Structure** :
Page avec plusieurs écrans (carousel) :

**Écran 1 : Bienvenue**
- Titre : "Bienvenue sur Sameva"
- Description : "Transformez votre quotidien en aventure"
- Illustration : Logo ou image de personnage
- Bouton : "Suivant"

**Écran 2 : Quêtes**
- Titre : "Créez vos quêtes"
- Description : "Organisez vos tâches comme des quêtes de héros"
- Illustration : Icône de quête
- Bouton : "Suivant"

**Écran 3 : Progression**
- Titre : "Progressez et montez en niveau"
- Description : "Gagnez de l'XP, collectez des items, devenez plus fort"
- Illustration : Barre de progression
- Bouton : "Suivant"

**Écran 4 : Personnalisation**
- Titre : "Personnalisez votre avatar"
- Description : "Équipez des tenues, des armes, des auras"
- Illustration : Avatar personnalisé
- Bouton : "Commencer"

**Fonctionnalités** :
- Navigation entre écrans (swipe ou boutons)
- Indicateur de progression (points ou barre)
- Animation de transition entre écrans
- Sauvegarde de l'état (ne plus afficher après première utilisation)
- Redirection vers la page d'accueil après le dernier écran

**Design** :
- Fond avec gradient ou image
- Cartes pour chaque écran
- Animations fluides
- Couleurs : Palette fantasy de l'app

**Stockage** :
- Utilise `SharedPreferences` pour sauvegarder si l'onboarding a été complété
- Clé : `onboarding_completed`

---

### 5. Écran de Chargement

**Fichier** : `lib/pages/loading_screen.dart`

**Description** :
Écran affiché pendant l'initialisation de l'application et la vérification de l'état d'authentification.

**Fonctionnalités** :
- Vérification de l'état d'authentification Firebase
- Vérification si l'onboarding a été complété
- Initialisation des providers
- Chargement des données utilisateur
- Redirection appropriée selon l'état

**Design** :
- Logo Sameva centré
- Indicateur de chargement (spinner ou animation)
- Fond sombre
- Animation subtile

**Flux** :
```
Loading → Vérification Auth → 
  ├─ Non connecté → Login
  ├─ Connecté + Onboarding fait → Home
  └─ Connecté + Onboarding non fait → Onboarding
```

---

## 🔄 Flux d'Authentification

### Premier Lancement

```
1. Splash Screen (2-3s)
   ↓
2. Loading Screen
   ↓
3. Vérification Auth
   ↓
4. Non connecté → Login Page
   ↓
5. Inscription → Register Page
   ↓
6. Compte créé → Onboarding
   ↓
7. Onboarding complété → Home
```

### Lancement Ultérieur (Non Connecté)

```
1. Splash Screen
   ↓
2. Loading Screen
   ↓
3. Login Page
   ↓
4. Connexion réussie → Home
```

### Lancement Ultérieur (Connecté)

```
1. Splash Screen
   ↓
2. Loading Screen
   ↓
3. Vérification Auth
   ↓
4. Session valide → Home
   ↓
5. Session expirée → Login
```

---

## 🔧 Intégration Firebase

### Configuration

**Fichier** : `lib/firebase_options.dart`

**Services utilisés** :
- **Firebase Auth** : Authentification email/password
- **Cloud Firestore** : Stockage des données utilisateur

### AuthProvider

**Fichier** : `lib/core/providers/auth_provider.dart`

**Méthodes principales** :
- `signInWithEmailAndPassword(email, password)` - Connexion
- `registerWithEmailAndPassword(email, password)` - Inscription
- `signInAnonymously()` - Connexion anonyme (test)
- `signOut()` - Déconnexion
- `getCurrentUser()` - Récupérer l'utilisateur actuel

**État** :
- `user` : Utilisateur Firebase actuel (null si non connecté)
- `isLoading` : État de chargement
- `error` : Message d'erreur

---

## 🎨 Design et UX

### Principes de Design

1. **Simplicité** : Formulaires clairs et intuitifs
2. **Feedback** : Messages d'erreur explicites
3. **Accessibilité** : Labels clairs, contraste suffisant
4. **Cohérence** : Style fantasy cohérent avec le reste de l'app

### Animations

- **Transitions** : Fade et slide entre pages
- **Loading** : Spinner ou animation Lottie
- **Succès** : Animation de confirmation (optionnel)

### Responsive

- Adaptation aux différentes tailles d'écran
- Support portrait et paysage (si nécessaire)
- Gestion du clavier (scroll automatique)

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Email invalide** : "Veuillez entrer un email valide"
2. **Mot de passe faible** : "Le mot de passe doit contenir au moins 6 caractères"
3. **Email déjà utilisé** : "Cet email est déjà associé à un compte"
4. **Mot de passe incorrect** : "Email ou mot de passe incorrect"
5. **Réseau** : "Erreur de connexion. Vérifiez votre connexion internet"

### Affichage

- Messages d'erreur sous les champs concernés
- Message d'erreur global en haut du formulaire
- SnackBar pour les erreurs critiques

---

## 🔒 Sécurité

### Bonnes Pratiques

1. **Validation côté client** : Vérification avant envoi
2. **Validation côté serveur** : Firebase gère la sécurité
3. **Mots de passe** : Minimum 6 caractères (Firebase)
4. **Sessions** : Gestion automatique par Firebase
5. **Déconnexion** : Option disponible dans les paramètres

### Mode Test

- Bypass d'authentification pour développement
- Peut être désactivé en production
- Identifiants par défaut : `test@test.com` / `password`

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Connexion avec Google/Apple
- [ ] Réinitialisation de mot de passe
- [ ] Vérification d'email
- [ ] Authentification à deux facteurs
- [ ] Biométrie (Touch ID / Face ID)
- [ ] "Se souvenir de moi"
- [ ] Connexion automatique

### Tests

- Tests unitaires pour la validation
- Tests d'intégration pour le flux complet
- Tests UI pour les pages

---

## 🔗 Liens Utiles

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Flutter Firebase Auth](https://firebase.flutter.dev/docs/auth/overview)






