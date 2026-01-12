# Guide de Configuration Supabase pour Sameva

## 📋 Vue d'ensemble

Ce guide vous explique comment configurer Supabase avec le schéma SQL complet pour l'application Sameva.

## 🚀 Étapes d'installation

### 1. Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Créez un compte ou connectez-vous
3. Cliquez sur "New Project"
4. Remplissez les informations :
   - **Name** : `sameva` (ou le nom de votre choix)
   - **Database Password** : Choisissez un mot de passe fort
   - **Region** : Choisissez la région la plus proche
5. Cliquez sur "Create new project"

### 2. Exécuter le schéma SQL

1. Dans votre projet Supabase, allez dans **SQL Editor** (dans le menu de gauche)
2. Cliquez sur **New Query**
3. Copiez tout le contenu du fichier `supabase_schema.sql`
4. Collez-le dans l'éditeur SQL
5. Cliquez sur **Run** (ou appuyez sur `Ctrl+Enter`)

✅ Le schéma devrait être créé avec succès !

### 3. Vérifier les tables créées

1. Allez dans **Table Editor** (dans le menu de gauche)
2. Vous devriez voir toutes les tables :
   - `users`
   - `items`
   - `user_inventory`
   - `user_equipment`
   - `companions`
   - `quests`
   - `transactions`

### 4. Configurer l'authentification

1. Allez dans **Authentication** > **Providers**
2. Activez **Email** provider (déjà activé par défaut)
3. Optionnel : Activez **Anonymous** sign-ins si vous voulez permettre la connexion anonyme

### 5. Récupérer les clés API

1. Allez dans **Settings** > **API**
2. Copiez :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon public** key : `eyJhbGci...`
3. Ajoutez-les dans votre fichier `.env` :

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

## 📊 Structure des Tables

### `users`
Extension de `auth.users` avec les statistiques du joueur :
- `level`, `experience`, `gold`, `crystals`
- `health_points`, `moral`, `streak`
- `achievements` (JSONB)

### `items`
Catalogue de tous les items disponibles dans le jeu.

### `user_inventory`
Inventaire des joueurs (items possédés avec quantité).

### `user_equipment`
Équipement actuellement porté par le joueur.

### `companions`
Compagnons possédés par les joueurs.

### `quests`
Quêtes créées par les joueurs.

### `transactions`
Historique de toutes les transactions (achats, ventes, récompenses).

## 🔒 Sécurité (RLS)

Toutes les tables ont **Row Level Security (RLS)** activé :
- Les utilisateurs ne peuvent voir/modifier que leurs propres données
- Les items sont visibles par tous les utilisateurs authentifiés
- Les transactions sont en lecture seule (insertion uniquement)

## 🧪 Tester la configuration

### Test 1 : Créer un utilisateur

Dans l'application Flutter :
1. Créez un compte avec email/password
2. Vérifiez dans Supabase > Table Editor > `users` qu'un profil a été créé automatiquement

### Test 2 : Vérifier le trigger

1. Allez dans **Table Editor** > `users`
2. Vous devriez voir votre utilisateur avec les valeurs par défaut :
   - `level` = 1
   - `gold` = 0
   - `crystals` = 0
   - etc.

### Test 3 : Créer une quête

Dans l'application :
1. Créez une quête
2. Vérifiez dans `quests` qu'elle apparaît bien

## 📝 Notes importantes

1. **Trigger automatique** : Quand un utilisateur s'inscrit, un profil est automatiquement créé dans `users` et un équipement vide dans `user_equipment`.

2. **Types ENUM** : Les types ENUM sont créés automatiquement et utilisés pour garantir l'intégrité des données.

3. **Index** : Des index ont été créés sur les colonnes fréquemment utilisées pour optimiser les performances.

4. **Cascade Delete** : Quand un utilisateur est supprimé, toutes ses données associées sont automatiquement supprimées.

## 🔧 Maintenance

### Ajouter des items de base

Vous pouvez ajouter des items dans la table `items` :

```sql
INSERT INTO public.items (name, description, type, rarity, value, is_equippable, attack_bonus)
VALUES 
  ('Épée en bois', 'Une simple épée en bois', 'weapon', 'common', 50, true, 5),
  ('Bouclier de cuir', 'Un bouclier basique', 'shield', 'common', 30, true, 0);
```

### Vérifier les performances

Dans **Database** > **Query Performance**, vous pouvez voir les requêtes les plus lentes et optimiser si nécessaire.

## 🆘 Dépannage

### Erreur : "relation already exists"
Si vous avez déjà exécuté le schéma, supprimez d'abord les tables existantes ou utilisez `DROP TABLE IF EXISTS`.

### Erreur : "permission denied"
Vérifiez que vous êtes connecté en tant qu'administrateur du projet.

### Les données ne s'affichent pas
Vérifiez que RLS est bien configuré et que vous êtes authentifié dans l'application.

## 📚 Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [Guide RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [API Reference](https://supabase.com/docs/reference/dart/introduction)

