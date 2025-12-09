# Migration de Firebase vers Supabase

## 📋 Vue d'ensemble

Cette migration remplace Firebase Auth par Supabase Auth. Supabase est une alternative open-source qui offre :
- ✅ Authentification similaire (email/password, anonyme)
- ✅ Base de données PostgreSQL intégrée (si besoin plus tard)
- ✅ Stockage de fichiers
- ✅ API REST automatique
- ✅ Gratuit jusqu'à 500MB de base de données

## ✅ Migration effectuée

La migration a été effectuée avec succès ! Voici ce qui a été modifié :

### 1. Dépendances (pubspec.yaml) ✅

**Supprimé :**
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
```

**Ajouté :**
```yaml
supabase_flutter: ^2.5.4
```

### 2. Fichiers modifiés ✅

1. **lib/main.dart** - Initialisation Supabase au lieu de Firebase
2. **lib/core/providers/auth_provider.dart** - Méthodes adaptées pour Supabase
3. **lib/config/supabase_config.dart** - Nouveau fichier de configuration
4. **lib/pages/quest/** - Remplacement de `user?.uid` par `userId`

### 3. Configuration Supabase requise

**⚠️ IMPORTANT :** Vous devez configurer vos clés Supabase avant de lancer l'application.

1. Créer un compte sur [supabase.com](https://supabase.com)
2. Créer un nouveau projet
3. Aller dans **Settings > API**
4. Récupérer :
   - **URL du projet** (ex: `https://xxxxx.supabase.co`)
   - **Clé API anonyme** (anon key)
5. **Créer un fichier `.env`** à la racine du projet :

```bash
# Copier le fichier exemple
cp .env.example .env
```

6. **Modifier le fichier `.env`** avec vos clés :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre-cle-anon-ici
```

**🔒 Sécurité :** Le fichier `.env` est automatiquement ignoré par Git (dans `.gitignore`) pour éviter de commiter vos clés secrètes.

### 4. Commandes à exécuter

```bash
# Installer les nouvelles dépendances
flutter pub get

# Nettoyer le projet
flutter clean

# Reconstruire
flutter pub get
```

## 🔄 Changements dans le code

### AuthProvider

**Avant (Firebase) :**
```dart
final FirebaseAuth _auth = FirebaseAuth.instance;
User? _user;
_user = _auth.currentUser;
await _auth.signInAnonymously();
```

**Après (Supabase) :**
```dart
final SupabaseClient _supabase = Supabase.instance.client;
User? _user;
_user = _supabase.auth.currentUser;
await _supabase.auth.signInAnonymously();
```

### Utilisation de l'ID utilisateur

**Avant :**
```dart
final userId = authProvider.user?.uid;
```

**Après :**
```dart
final userId = authProvider.userId; // Getter ajouté dans AuthProvider
```

## 📝 Fonctionnalités migrées

- ✅ Connexion anonyme (`signInAnonymously`)
- ✅ Connexion email/password (`signInWithEmailAndPassword`)
- ✅ Création de compte (`createUserWithEmailAndPassword`)
- ✅ Déconnexion (`signOut`)
- ✅ Écoute des changements d'état d'authentification
- ✅ Récupération de l'utilisateur actuel

## ⚠️ Notes importantes

1. **Les utilisateurs existants** : Les comptes Firebase ne seront pas migrés automatiquement. Les utilisateurs devront se réinscrire.

2. **Fichier firebase_options.dart** : Peut être supprimé (plus nécessaire), mais conservé pour référence.

3. **Authentification anonyme** : Fonctionne de la même manière avec Supabase.

4. **Structure des données** : Si vous utilisez Firestore, vous devrez migrer vers Supabase PostgreSQL (non fait dans cette migration car seul Auth était utilisé).

## 🧪 Tests

Après configuration, tester :
1. Connexion anonyme
2. Création de compte avec email/password
3. Connexion avec email/password
4. Déconnexion
5. Persistance de session au redémarrage

## 📚 Documentation Supabase

- [Documentation Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Guide d'authentification](https://supabase.com/docs/guides/auth)
- [API Reference](https://supabase.com/docs/reference/dart/auth-signinwithpassword)

