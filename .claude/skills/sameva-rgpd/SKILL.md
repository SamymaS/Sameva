---
name: sameva-rgpd
description: Carte de suppression des données utilisateur (RGPD, droit à l'effacement) pour Sameva. Déclenche sur : "RGPD", "suppression de compte", "delete account", "droit à l'effacement", "effacer mes données", "purge", "anonymisation", "export de données".
---

# Suppression des données utilisateur (RGPD) — Sameva

Carte d'effacement complet d'un utilisateur. Dérivée du schéma réel
(`supabase/migrations/`, `documentation/supabase_schema.sql`). **Vérifier le
schéma courant avant d'agir** : une migration récente peut avoir ajouté une table.

> État au moment de l'écriture : aucune Edge Function de suppression n'existe, et
> aucun appel `admin.deleteUser` n'est implémenté. Il faut donc l'outiller.

## 1. Graphe des données Supabase

Tout descend de `auth.users` en `ON DELETE CASCADE`, sauf une table d'audit.

```
auth.users
├── public.users                  (CASCADE)   → profil joueur
│   ├── public.quests             (CASCADE)
│   ├── public.user_inventory     (CASCADE)
│   ├── public.user_equipment     (CASCADE)
│   ├── public.companions         (CASCADE)
│   └── public.transactions       (CASCADE)
├── public.player_stats           (CASCADE)
├── public.ai_validation_credits  (CASCADE)
└── public.premium_subscriptions  (CASCADE)

public.quest_difficulty_audit  ⚠ user_id SANS FK → jamais purgée par cascade
```

`public.items` est un catalogue global (pas de `user_id`) — ne pas toucher.
`public.leaderboard_view` est une vue sur `player_stats`+`users` : elle se vide
d'elle-même une fois ces tables purgées, aucune action requise.

## 2. Ordre de DELETE FK-safe

Comme presque tout est en CASCADE depuis `auth.users`, l'effacement tient en
deux étapes :

```sql
-- Étape 1 : table d'audit orpheline (aucune FK CASCADE ne la couvre)
DELETE FROM public.quest_difficulty_audit WHERE user_id = $userId;
```

```ts
// Étape 2 : suppression du compte auth → déclenche TOUTES les cascades
//   public.users (→ quests, user_inventory, user_equipment, companions, transactions)
//   public.player_stats, ai_validation_credits, premium_subscriptions
await supabaseAdmin.auth.admin.deleteUser(userId)
```

Si un jour une nouvelle table per-user est ajoutée **sans** CASCADE vers
`auth.users`, l'ajouter à l'étape 1.

## 3. Edge Function de suppression (à créer)

Pattern : Edge Function dédiée, client `service_role`, suppression auto-ciblée.

- **Garde de sécurité impérative** : l'utilisateur ne peut effacer **que son
  propre compte**. Extraire l'`userId` du **JWT de l'appelant** et exiger
  `jwt.sub === userId` (cible). Ne jamais accepter un `userId` arbitraire du body
  sans cette vérification — sinon n'importe qui efface n'importe qui.
- `verify_jwt` doit rester **activé** (contrairement à `stripe-webhook` qui le
  désactive volontairement).
- Service role uniquement côté serveur ; jamais exposer la clé au client.
- Voir la skill `sameva-edge-functions` pour le squelette Deno/CORS/secrets.

```ts
// 1. Authentifier l'appelant (anon client + Authorization header)
// 2. const { data: { user } } = await anon.auth.getUser()
// 3. if (!user) → 401
// 4. DELETE quest_difficulty_audit WHERE user_id = user.id   (service_role)
// 5. await admin.auth.admin.deleteUser(user.id)               (service_role)
```

## 4. Purge locale Hive

Boîtes ouvertes dans `lib/main.dart` : `quests`, `playerStats`, `settings`,
`inventory`, `equipment`, `cats`, `aiValidation`.

`AuthViewModel._purgeHiveData()` (au `signOut`) efface déjà : `playerStats['stats']`,
`inventory['items']`, `equipment['equipment']`/`['cosmetics']`,
`settings['achievements']`. **Mais une suppression de compte doit aller plus
loin** que le simple logout — purger aussi les clés per-user laissées en place :

| Boîte | Clé per-user à supprimer | Aujourd'hui purgée au logout ? |
|---|---|---|
| `cats` | `cats_list_$userId` | Non (reset mémoire seulement) |
| `aiValidation` | `ai_validation_$userId` | Non (reset mémoire seulement) |
| `settings` | `has_onboarded_$userId` | Non |
| `settings` | `lastFreePullAt` | Non |

Pour un effacement RGPD : appeler `_purgeHiveData()` **plus** la suppression
explicite de ces 4 clés per-user.

## 5. Réutiliser `onSignedOut`

`AuthViewModel` expose `Stream<void> get onSignedOut` (broadcast). Y sont déjà
abonnés (→ `reset()`) : `PlayerViewModel`, `InventoryViewModel`,
`EquipmentViewModel`, `CatViewModel`, `AiValidationCreditsService`.
La suppression de compte se **termine par un signOut**, ce qui propage ces resets
mémoire gratuitement. (Note : `QuestViewModel` n'est pas abonné — vider son cache
explicitement si nécessaire.)

Flux complet : Edge Function (Supabase + audit) → purge Hive étendue → `signOut()`
(propage `onSignedOut`) → retour à `LoginPage` via `_AuthGate`.

## 6. UI — confirmation irréversible

La suppression est **destructive et définitive**. Côté UI (page Réglages) :
- Confirmation explicite à double palier (dialog « Êtes-vous sûr ? » +
  re-saisie/typing d'un mot de validation), jamais un simple tap.
- Texte clair : ce qui sera effacé (progression, quêtes, achats premium, chats).
- État de chargement bloquant pendant l'appel réseau, gestion d'erreur (l'Edge
  Function peut échouer — ne pas faire croire à un succès).
- Suivre les conventions de confirmation déjà en place (cf. déconnexion dans
  `profile_page.dart`).
