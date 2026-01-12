# Authentification Supabase - Sameva

## ✅ Modifications effectuées

### 1. AuthProvider amélioré (`lib/presentation/providers/auth_provider.dart`)

- ✅ Gestion des erreurs avec messages en français
- ✅ État de chargement (`isLoading`)
- ✅ Messages d'erreur personnalisés
- ✅ Validation des champs (email, mot de passe)
- ✅ Méthodes :
  - `signInWithEmailAndPassword()` - Connexion avec email/mot de passe
  - `createUserWithEmailAndPassword()` - Inscription avec email/mot de passe
  - `signInAnonymously()` - Connexion anonyme
  - `signOut()` - Déconnexion

### 2. Page de connexion (`lib/ui/pages/auth/login_page.dart`)

- ✅ Validation des champs (email non vide, mot de passe non vide)
- ✅ Gestion des erreurs avec affichage de messages
- ✅ Indicateur de chargement
- ✅ Bouton "Créer un compte" pour naviguer vers l'inscription
- ✅ Bouton "Continuer sans compte" pour connexion anonyme

### 3. Page d'inscription (`lib/ui/pages/auth/register_page.dart`)

- ✅ Validation complète :
  - Email non vide et valide (contient @)
  - Mot de passe minimum 6 caractères
  - Confirmation du mot de passe correspond
- ✅ Gestion des erreurs avec messages clairs
- ✅ Message de succès après création du compte
- ✅ Indicateur de chargement

### 4. Redirection automatique (`lib/app_new.dart`)

- ✅ Redirection vers la page de login si l'utilisateur n'est pas connecté
- ✅ Affichage de l'application principale si l'utilisateur est connecté

### 5. Création du fichier `app_colors.dart`

- ✅ Toutes les couleurs de l'application centralisées
- ✅ Couleurs de rareté pour items/quêtes
- ✅ Couleurs d'état (success, error, warning, info)

## 🔄 Fonctionnement avec Supabase

### Création automatique de l'utilisateur

Quand un utilisateur s'inscrit :
1. Supabase Auth crée l'utilisateur dans `auth.users`
2. Le trigger `handle_new_user()` (défini dans `supabase_schema.sql`) crée automatiquement :
   - Un profil dans la table `users` avec les valeurs par défaut
   - Un équipement vide dans la table `user_equipment`

**Aucune action supplémentaire n'est nécessaire dans le code Flutter !**

### Schéma SQL

Le schéma SQL complet se trouve dans `documentation/supabase_schema.sql` et inclut :
- ✅ Table `users` (extension de `auth.users`)
- ✅ Table `items` (catalogue d'items)
- ✅ Table `user_inventory` (inventaire des joueurs)
- ✅ Table `user_equipment` (équipement actuel)
- ✅ Table `companions` (compagnons)
- ✅ Table `quests` (quêtes)
- ✅ Table `transactions` (historique)
- ✅ RLS (Row Level Security) activé sur toutes les tables
- ✅ Triggers pour création automatique

## 📝 Prochaines étapes

### 1. Tester l'authentification

1. Exécutez le schéma SQL dans Supabase (si pas déjà fait)
2. Lancez l'application : `flutter run`
3. Testez :
   - Création d'un compte avec email/mot de passe
   - Connexion avec les identifiants créés
   - Connexion anonyme
   - Vérification dans Supabase > Table Editor > `users` qu'un profil a été créé

### 2. Intégrer les quêtes avec Supabase

- Modifier `QuestProvider` pour utiliser Supabase au lieu de Hive
- Créer un repository pour les quêtes (`lib/data/repositories/quest_repository.dart`)
- Utiliser la table `quests` du schéma SQL

### 3. Intégrer les items avec Supabase

- Modifier `InventoryProvider` pour utiliser Supabase
- Créer un repository pour l'inventaire
- Utiliser les tables `items` et `user_inventory`

### 4. Intégrer les statistiques joueur

- Modifier `PlayerProvider` pour utiliser Supabase
- Utiliser la table `users` pour les stats (level, experience, gold, etc.)

## 🔒 Sécurité

- ✅ RLS (Row Level Security) activé : les utilisateurs ne peuvent voir/modifier que leurs propres données
- ✅ Validation côté client ET serveur
- ✅ Gestion sécurisée des mots de passe (hashés par Supabase)
- ✅ Tokens JWT pour l'authentification

## 📚 Documentation

- Schéma SQL : `documentation/supabase_schema.sql`
- Guide de configuration : `documentation/SUPABASE_SETUP.md`
- Architecture : `doc/ARCHITECTURE.md`

