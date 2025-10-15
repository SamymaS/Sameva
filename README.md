# Sameva

Sameva est une application mobile Flutter en cours de développement qui transforme l'organisation personnelle en expérience RPG. Le projet mise sur une atmosphère pastel, des animations fluides et une progression de personnage pour rendre le suivi des objectifs quotidiens plus engageant.

## Aperçu du produit
- **Onboarding animé** : parcours introductif en trois étapes basé sur des animations Lottie avec persistance de l'état dans `SharedPreferences` pour éviter de le rejouer une fois terminé.
- **Authentification Firebase** : connexion par email/mot de passe, anonymat et suivi automatique de session via `FirebaseAuth`.
- **Gestion des quêtes** : création locale, listing et marquage comme terminées avec synchronisation Firestore (collection `users/<uid>/quests`). Un écran de détail affiche rareté, fréquence et sous-quêtes.
- **Progression du joueur** : statistiques RPG (niveau, XP, or, PV, crédibilité) chargées/sauvegardées dans Firestore et présentées via une carte dédiée, avec gains d'XP et d'or lors de la validation d'une quête.
- **Cœur de navigation** : une `RootShell` à 4 onglets (Accueil, Récompenses, Profil, Paramètres) animés avec `AnimatedSwitcher` et un bouton d'action flottant pour créer une quête.
- **Personnalisation visuelle** : thèmes clair/sombre basés sur une palette pastel, polices médiévales et stockage du mode choisi via Hive.
- **Pages complémentaires** : boutique de récompenses statique, profil joueur (statistiques réutilisées) et paramètres de compte/déconnexion.

> ℹ️ Le projet est encore en phase de prototypage : plusieurs écrans affichent des données factices ou n'écrivent pas encore dans Firestore, et certaines intégrations (OpenAI, boutique, succès…) restent à implémenter.

## Feuille de route
- Génération assistée par IA des sous-quêtes via le service OpenAI déjà configuré (mais non raccordé à l'UI).
- Persistance complète de la création de quêtes (formulaire `CreateQuestPage`) et édition en temps réel.
- Récompenses dynamiques et boutique avec dépenses d'or.
- Profil enrichi (succès, historique, personnalisation d'avatar).
- Notifications, widgets/animations supplémentaires et polissage des transitions.

## Architecture du code
```
lib/
├── app.dart               # Configuration MaterialApp et routes principales
├── main.dart              # Initialisation Firebase, Hive, Provider et OpenAI
├── config/                # Chargement des variables d'environnement (.env)
├── core/
│   ├── providers/         # Auth, quêtes, joueur, thème (state management Provider)
│   └── ...
├── pages/                 # Vues : onboarding, auth, home, rewards, profile, settings…
│   ├── home/widgets/      # Composants spécifiques (liste de quêtes, carte de stats)
│   └── quest/             # Détails et création des quêtes
├── services/              # Intégrations Firebase & OpenAI
├── theme/                 # Thèmes, styles et palette de couleurs
└── widgets/               # Composants transverses (à étendre)
```

### Navigation & transitions
- `App` choisit la page de lancement selon l'onboarding (`SharedPreferences`) puis l'état d'authentification (`AuthProvider`).
- La navigation nommée expose : `/`, `/login`, `/rewards`, `/profile`, `/settings`, `/onboarding`, `/quest/details` avec transitions personnalisées (fondu + léger slide).
- `RootShell` orchestre les onglets bas et le bouton d'ajout de quête avec animations Material 3.

## Stack technique
- **Flutter** (SDK ≥ 3.3) & **Dart**.
- **Firebase** : `firebase_core`, `firebase_auth`, `cloud_firestore` pour l'authentification et la persistance des quêtes/statistiques.
- **State management** : `provider`.
- **Stockage local** : `hive`/`hive_flutter` (préférences thème) et `shared_preferences` (onboarding).
- **UI & animations** : `google_fonts`, `lottie`, `flutter_animate`, `flutter_svg`.
- **Intégrations externes** : `dart_openai` pour la génération de contenu ; `uuid` pour les identifiants de quêtes.

## Prise en main
### Prérequis
- Flutter SDK 3.3 ou plus récent et Dart 3.3+.
- Un projet Firebase configuré (Authentication + Firestore).
- (Optionnel) Une clé API OpenAI pour activer les suggestions de sous-quêtes.

### Installation
```bash
git clone https://github.com/<votre-utilisateur>/sameva.git
cd sameva
flutter pub get
```

### Variables d'environnement
Créez un fichier `.env` à la racine (chargé par `EnvConfig`) :
```
FIREBASE_API_KEY=...
FIREBASE_AUTH_DOMAIN=...
FIREBASE_PROJECT_ID=...
FIREBASE_STORAGE_BUCKET=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_APP_ID=...
OPENAI_API_KEY=... # Optionnel mais recommandé
```

### Configuration Firebase
1. Activez Authentication (email/mot de passe + anonyme) et Cloud Firestore.
2. Générez et placez les fichiers de configuration :
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Vérifiez que les règles Firestore autorisent l'accès aux collections `users/<uid>/quests` et `users/<uid>/stats`.

### Lancer l'application
```bash
flutter run
```

## Développement
- Les préférences (thème, onboarding) sont stockées localement ; pensez à nettoyer Hive/SharedPreferences lors de tests d'intégration.
- Les quêtes et statistiques reposent sur la structure Firestore suivante :
  - `users/{uid}/quests/{questId}` → `Quest.toJson()`.
  - `users/{uid}` (document) → champ `stats` mappé depuis `PlayerStats`.
- Pour ajuster la palette ou les styles, modifiez `lib/theme/app_theme.dart` et `lib/theme/app_styles.dart`.
- Les routes supplémentaires doivent être enregistrées dans `App.onGenerateRoute` pour bénéficier des transitions animées.

## Contribution
Les retours et contributions sont bienvenus : créez une issue ou une Pull Request après avoir synchronisé votre branche et respecté la structure existante.

---
> « Héros de ta vie. Tes quêtes. Ton aventure. »
