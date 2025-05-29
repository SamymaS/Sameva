# Sameva - Votre vie en mode RPG 🎮

Sameva est une application mobile gamifiée d'organisation personnelle qui transforme vos tâches quotidiennes en quêtes inspirées des jeux de rôle (RPG).

## 🚀 Fonctionnalités

- Système de quêtes et sous-quêtes personnalisables
- Avatar personnalisable avec progression RPG
- Système de récompenses et de progression
- Interface immersive avec animations et effets sonores
- Intégration IA pour la décomposition des tâches
- Mode sombre/clair adaptatif

## 📋 Prérequis

- Flutter SDK (^3.7.2)
- Dart SDK (^3.0.0)
- Un compte Firebase
- Une clé API OpenAI (pour la génération de sous-tâches)

## 🛠️ Installation

1. Clonez le dépôt :
```bash
git clone https://github.com/votre-username/sameva.git
cd sameva
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Créez un fichier `.env` à la racine du projet avec les variables suivantes :
```
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_MESSAGING_SENDER_ID=your_firebase_sender_id
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key

# App Configuration
APP_NAME=Sameva
APP_VERSION=1.0.0
APP_ENV=development
```

4. Configurez Firebase :
   - Créez un projet sur la console Firebase
   - Ajoutez une application Android/iOS
   - Téléchargez les fichiers de configuration
   - Placez-les dans les dossiers appropriés :
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

## 🎨 Structure du projet

```
lib/
├── core/
│   ├── app.dart
│   ├── models/
│   ├── providers/
│   └── services/
├── pages/
│   ├── splash/
│   ├── home/
│   ├── quest/
│   └── profile/
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── common/
    └── quest/
```

## 🔧 Configuration

### Thème

Le thème de l'application est configurable dans `lib/theme/app_theme.dart`. Vous pouvez modifier :
- Les couleurs principales
- Les styles de texte
- Les animations
- Les effets visuels

### Firebase

1. Activez les services Firebase nécessaires :
   - Authentication
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions (optionnel)

2. Configurez les règles de sécurité pour Firestore et Storage

### Notifications

Les notifications sont configurées pour être :
- Non intrusives
- Personnalisées selon les habitudes de l'utilisateur
- Adaptées au fuseau horaire

## 📱 Lancement

```bash
flutter run
```

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🙏 Remerciements

- L'équipe Flutter pour ce framework incroyable
- La communauté open source pour les packages utilisés
- Tous les contributeurs du projet

# 🧭 Sameva – L'application de quête personnelle

**Sameva** est une application mobile gamifiée développée avec **Flutter**, conçue pour transformer vos tâches quotidiennes en aventures RPG. 🧙‍♂️

---

## ✨ Fonctionnalités principales

- 🎯 Création de **quêtes journalières ou hebdomadaires**
- 🧩 Décomposition automatique des quêtes en sous-tâches
- ⚔️ Gagnez des **XP**, de l'**or**, et montez de **niveau**
- 💀 Système de **malus** (perte de vie si oubli)
- 🛡️ Boutique avec objets, familiers, personnalisations
- 👥 Système de **groupes & événements multijoueur**
- 💬 Tchat communautaire, leaderboard, avatar évolutif

---

## 🛠️ Stack technique

- **Flutter** & **Dart**
- Gestion d'état : `Provider` (ou `Riverpod`)
- Backend à venir (Firebase, Supabase ou Node.js)
- Animations & SFX immersifs (orbe, particules, splashs)
- Compatible Android & iOS

---

## 📁 Structure du projet

```bash
lib/
├── pages/          # Écrans (Splash, Loading, Home)
├── models/         # Données (Quêtes, User, Shop, etc.)
├── services/       # Gestion logique (auth, quêtes)
├── widgets/        # Composants UI réutilisables
assets/
├── images/
├── sounds/
```

---

## 🎨 Design system

- Couleurs pastel douces
- UI flat & épurée
- Icônes RPG (plume, parchemin, orbe)
- Navigation fluide avec animations

---

## 📌 À venir

- 🔐 Authentification Google
- ☁️ Backend Cloud
- 🗓️ Notifications & rappels intelligents
- 🎁 Système de récompenses
- Création d'IA ?

---

## 📬 Auteur

**Samy Boudaoud**  
📧 samyboudaoud95@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/samy-boudaoud/)

---

> _"Héros de ta vie. Tes quêtes. Ton aventure."_ ⚔️  
