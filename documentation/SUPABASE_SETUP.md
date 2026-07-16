# Configuration Supabase

Ce guide décrit la mise en place complète du backend Sameva : base de données, authentification, clés et Edge Functions.

---

## 1. Créer le projet

1. Aller sur [supabase.com](https://supabase.com) et créer un projet.
2. Noter le mot de passe de la base et choisir la région la plus proche.
3. Récupérer le **Reference ID** (Settings, General) : il sert à lier la CLI.

---

## 2. Appliquer le schéma

Le schéma se compose de deux éléments complémentaires.

**a. Schéma de base** : `documentation/supabase_schema.sql` contient les sept tables fondatrices (`users`, `items`, `user_inventory`, `user_equipment`, `companions`, `quests`, `transactions`), leurs types énumérés, index, triggers et politiques RLS. À exécuter une fois dans SQL Editor, New Query, Run.

**b. Migrations versionnées** : `supabase/migrations/` contient les évolutions ultérieures, à appliquer ensuite :

```bash
supabase link --project-ref VOTRE_PROJECT_REF
supabase db push
```

| Migration | Apport |
| --------- | ------ |
| `player_stats` | Table de synchronisation des stats joueur entre appareils |
| `quest_difficulty_check` | Table d'audit `quest_difficulty_audit`, correction des données historiques et contrainte `CHECK difficulty BETWEEN 1 AND 4` |
| `harden_rls_policies` | Durcissement des politiques RLS |
| `companions_sync_support` | Synchronisation des compagnons |
| `document_leaderboard_view_security` | Documentation du modèle de sécurité de `leaderboard_view` |
| `ai_validation_credits` (+ correctif) | Portefeuille de jetons de validation IA |
| `premium_subscriptions` | État de l'abonnement premium |

> **Limite connue** : le schéma de base n'est pas encore versionné sous forme de migration initiale. Sur une instance vierge, les migrations qui référencent `quests` échouent tant que `supabase_schema.sql` n'a pas été exécuté. Une migration initiale versionnée est prévue pour rendre la reconstruction entièrement reproductible.

---

## 3. Tables

| Table | Rôle | Origine |
| ----- | ---- | ------- |
| `users` | Profil joueur, extension de `auth.users` | schéma de base |
| `quests` | Quêtes créées par les joueurs | schéma de base |
| `items` | Catalogue d'items | schéma de base |
| `user_inventory` | Inventaire persistant | schéma de base |
| `user_equipment` | Équipement porté | schéma de base |
| `companions` | Compagnons possédés | schéma de base |
| `transactions` | Historique des transactions | schéma de base |
| `player_stats` | Stats joueur synchronisées (niveau, XP, or, HP, streak, succès) | migration |
| `quest_difficulty_audit` | Journal d'audit de la correction de difficulté | migration |
| `ai_validation_credits` | Portefeuille de jetons par utilisateur | migration |
| `premium_subscriptions` | Abonnement premium par utilisateur | migration |

Une vue, `leaderboard_view`, expose une projection publique restreinte pour le classement.

> **État d'usage** : l'application lit et écrit `quests`, `users`, `player_stats`, `companions`, `user_equipment`, `ai_validation_credits`, `premium_subscriptions` et `leaderboard_view`. Les tables `items`, `user_inventory` et `transactions` existent dans le schéma mais ne sont pas encore consommées : l'inventaire et les transactions sont actuellement gérés en local (Hive). Elles constituent la cible de la synchronisation à venir.

---

## 4. Authentification

Dans Authentication, Providers :

1. Activer **Email** (actif par défaut).
2. Activer **Anonymous sign-ins** pour permettre l'essai sans compte.

Un trigger crée automatiquement le profil dans `users` et un équipement vide à l'inscription.

---

## 5. Clés et fichier `.env`

Dans Settings, API, copier le Project URL et la clé **anon public**, puis renseigner `.env` à la racine du projet Flutter :

```env
SUPABASE_URL=https://VOTRE_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ...
VALIDATION_AI_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof
SUGGEST_QUESTS_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/suggest-quests
```

La clé anon est publique par conception : elle est protégée par la RLS. La clé `service_role` ne doit **jamais** être placée dans `.env` ni dans l'application ; elle est injectée automatiquement dans les Edge Functions par la plateforme.

---

## 6. Sécurité (RLS)

La Row Level Security est activée sur toutes les tables, chaque politique filtrant sur `auth.uid() = user_id`. Conséquences notables :

- Un utilisateur ne lit et n'écrit que ses propres données.
- L'entitlement premium est en **lecture seule** côté client : seule la fonction `stripe-webhook`, en `service_role`, peut l'écrire. L'élévation de privilège depuis le client est donc impossible.
- Le classement passe par une vue à projection restreinte plutôt que par un accès direct aux tables.

---

## 7. Edge Functions

Le déploiement des cinq fonctions et la configuration des secrets (`ANTHROPIC_API_KEY`, clés Stripe) sont décrits dans [SUPABASE_EDGE_FUNCTION_IA.md](SUPABASE_EDGE_FUNCTION_IA.md).

---

## 8. Vérifier l'installation

1. Créer un compte depuis l'application, puis vérifier qu'une ligne apparaît dans `users` avec `level = 1`.
2. Créer une quête et vérifier qu'elle apparaît dans `quests`.
3. Valider une quête par photo et vérifier que le solde de `ai_validation_credits` décroît.

---

## 9. Dépannage

| Symptôme | Piste |
| -------- | ----- |
| `relation already exists` | Le schéma a déjà été exécuté ; ne pas le rejouer |
| `relation "quests" does not exist` lors d'une migration | Exécuter `supabase_schema.sql` avant `supabase db push` |
| `permission denied` / données invisibles | Vérifier l'authentification et les politiques RLS |
| La validation IA renvoie 502 | Vérifier `ANTHROPIC_API_KEY` via `supabase secrets list` |
