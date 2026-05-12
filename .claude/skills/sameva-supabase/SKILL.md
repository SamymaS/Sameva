---
name: sameva-supabase
description: Patterns d'accès à Supabase dans Sameva — auth, requêtes SQL, RLS, repositories. À utiliser pour toute interaction avec la base de données, l'authentification, le storage, ou les RLS policies. Pour les Edge Functions, voir sameva-edge-functions.
---

# Supabase Sameva

## Configuration

```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static String? get supabaseUrl => dotenv.env['SUPABASE_URL'];
  static String? get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'];
  static String? get validationAiUrl => dotenv.env['VALIDATION_AI_URL'];
}
```

Clés dans `.env` (non versionné) :
```env
SUPABASE_URL=https://<PROJECT_REF>.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
VALIDATION_AI_URL=https://<PROJECT_REF>.supabase.co/functions/v1/analyze-quest-proof
```

Initialisation dans `main.dart` avant `runApp` :
```dart
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl!,
  anonKey: SupabaseConfig.supabaseAnonKey!,
);
```

## Tables principales

| Table | Rôle | RLS |
|---|---|---|
| `auth.users` | Auth Supabase (géré nativement) | natif |
| `quests` | Quêtes (à faire, terminées, manquées) | ✅ user_id = auth.uid() |
| `player_stats` | Niveau, XP, or, cristaux, HP, moral, streak | ✅ user_id = auth.uid() |
| `inventory` | 50 emplacements, items du joueur | ✅ user_id = auth.uid() |
| `equipment` | Slots équipés (arme, armure, casque, bottes, anneau) | ✅ user_id = auth.uid() |
| `validations` | Logs des validations MougiBot (score, explanation) | ✅ user_id = auth.uid() |

**RLS obligatoire sur toutes les tables utilisateur.** Aucune table publique en lecture/écriture.

## Auth

```dart
// Connexion email
await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Connexion anonyme (mode invité)
await Supabase.instance.client.auth.signInAnonymously();

// Récupérer user courant
final user = Supabase.instance.client.auth.currentUser;
final userId = user?.id;

// Écoute des changements d'auth (dans AuthProvider)
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  // notifyListeners()
});
```

## Pattern de requête type

**Lecture** :
```dart
final response = await Supabase.instance.client
    .from('quests')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);
final quests = (response as List)
    .map((json) => QuestModel.fromJson(json))
    .toList();
```

**Upsert** :
```dart
await Supabase.instance.client
    .from('player_stats')
    .upsert({
      'user_id': userId,
      'level': level,
      'experience': xp,
      'updated_at': DateTime.now().toIso8601String(),
    });
```

**Suppression** :
```dart
await Supabase.instance.client
    .from('quests')
    .delete()
    .eq('id', questId)
    .eq('user_id', userId);  // garde-fou même si RLS actif
```

## Règles de l'art

1. **Toutes les requêtes passent par les providers**, jamais depuis l'UI directement
2. **Toujours filtrer par `user_id`** côté requête, même si RLS le force déjà (défense en profondeur)
3. **Toujours `try/catch`** autour des appels Supabase + fallback Hive si possible
4. **Convertir timestamps** en `DateTime.toIso8601String()` pour PostgreSQL
5. **Pas de SQL brut** depuis Flutter, utiliser uniquement le query builder

## RLS policies type

```sql
-- Lecture
CREATE POLICY "Lecture par propriétaire" ON quests
  FOR SELECT USING (user_id = auth.uid());

-- Insertion
CREATE POLICY "Insertion par propriétaire" ON quests
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Update
CREATE POLICY "Update par propriétaire" ON quests
  FOR UPDATE USING (user_id = auth.uid());

-- Delete
CREATE POLICY "Delete par propriétaire" ON quests
  FOR DELETE USING (user_id = auth.uid());
```

## Migrations SQL

```bash
# Créer une migration
supabase migration new <nom_lisible>

# Appliquer en local
supabase db reset

# Pousser en prod
supabase db push
```

Fichiers dans `supabase/migrations/`. Toujours versionner.

## Sync Hive ↔ Supabase

**Stratégie** : Hive en cache local + source de vérité Supabase.

- **Lecture** : lire Hive d'abord (instantané), puis refresh depuis Supabase en arrière-plan
- **Écriture** : écrire Hive immédiatement (UX réactive), pousser vers Supabase en arrière-plan
- **Conflits** : Supabase gagne en cas de divergence (last-write-wins via `updated_at`)

## Erreurs courantes

| Erreur | Cause probable | Solution |
|---|---|---|
| `PostgrestException: 401` | RLS empêche l'accès, pas d'auth | Vérifier `currentUser` non nul |
| `PostgrestException: 400` | Colonne inexistante ou type invalide | Vérifier le schéma DB |
| `RLS violation` | Policy bloque l'opération | Ajuster policy ou inclure `user_id` |
| `Network error` | Hors ligne | Fallback Hive, retry plus tard |

## Storage (si utilisé)

```dart
// Upload temporaire (pour MougiBot par exemple)
final response = await Supabase.instance.client.storage
    .from('quest-proofs')
    .uploadBinary('temp/${quest.id}.jpg', imageBytes);

// Pour MougiBot, on préfère envoyer l'image en base64 directement dans
// le body de l'Edge Function plutôt que de la stocker.
```

## Fichiers de référence

- `lib/config/supabase_config.dart`
- `lib/presentation/providers/auth_provider.dart`
- `lib/presentation/providers/quest_provider.dart`
- `supabase/migrations/`
