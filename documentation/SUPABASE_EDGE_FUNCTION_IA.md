# Mise en place de l’IA d’analyse d’image avec Supabase Edge Functions

Ce guide décrit comment configurer et déployer l’Edge Function **analyze-quest-proof** (OpenAI GPT-4 Vision) et brancher l’app Flutter dessus.

Références Supabase :
- [Getting Started with Edge Functions (Quickstart)](https://supabase.com/docs/guides/functions/quickstart)
- [Edge Functions – Overview](https://supabase.com/docs/guides/functions)

---

## 1. Prérequis

- **Supabase CLI** installé : [Installation](https://supabase.com/docs/guides/cli)
- Un **projet Supabase** créé sur [database.new](https://database.new)
- Une **clé API OpenAI** (modèle Vision, ex. GPT-4o) : [OpenAI API Keys](https://platform.openai.com/api-keys)

### Installation de la CLI Supabase sur Windows (PowerShell)

Si la commande `supabase` n’est pas reconnue :

**Option A — Scoop (recommandé)**

1. Ouvrir PowerShell en tant qu’administrateur et autoriser les scripts :
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
2. Installer Scoop puis Supabase :
   ```powershell
   iwr -useb get.scoop.sh | iex
   scoop install supabase
   ```
3. Vérifier : `supabase --version`

**Option B — npm (sans installer Scoop)**

1. Installer [Node.js](https://nodejs.org/) (v20+).
2. À la racine du projet :
   ```powershell
   npm install supabase --save-dev
   ```
3. Utiliser la CLI via `npx` :
   ```powershell
   npx supabase login
   npx supabase link --project-ref VOTRE_PROJECT_ID
   npx supabase secrets set OPENAI_API_KEY=sk-...
   npx supabase functions deploy analyze-quest-proof
   ```

---

## 2. Structure créée dans le projet

```
supabase/
  config.toml
  functions/
    analyze-quest-proof/
      index.ts
```

- **config.toml** : configuration Supabase (projet, API, auth, functions avec `verify_jwt = true`).
- **analyze-quest-proof** : Edge Function qui reçoit `image_base64`, `quest_title`, `quest_category` et renvoie `{ score, explanation }` via OpenAI Vision.

---

## 3. Lier le projet local à Supabase

À la racine du projet (Sameva) :

```bash
supabase login
supabase projects list
supabase link --project-ref VOTRE_PROJECT_ID
```

Remplacer `VOTRE_PROJECT_ID` par l’ID du projet (ex. `abcdefghijklmnop`).

---

## 4. Changer / configurer la base Supabase (projet)

Pour utiliser un **autre projet** Supabase (ou le lier pour la première fois) :

1. Créer un projet sur [database.new](https://database.new) si besoin.
2. Récupérer l’**ID du projet** : Dashboard Supabase → Settings → General → **Reference ID**.
3. Lier le repo local à ce projet :
   ```powershell
   supabase login
   supabase link --project-ref VOTRE_PROJECT_ID
   ```
   (Si déjà lié à un autre projet, `supabase link` remplace la liaison.)
4. Mettre à jour le fichier **.env** à la racine du projet Flutter :
   ```env
   SUPABASE_URL=https://VOTRE_PROJECT_REF.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   VALIDATION_AI_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof
   ```
   L’URL et la clé anon se trouvent dans Dashboard → **Settings → API**.

---

## 5. Configurer le secret OpenAI

**Sécurité :** Ne partage jamais ta clé API OpenAI (ni dans le code, ni dans le chat). Si tu l’as exposée, révoque-la sur [platform.openai.com/api-keys](https://platform.openai.com/api-keys) et génère une nouvelle clé.

La clé OpenAI ne doit **jamais** être dans le code ni dans le client. On la met dans les **secrets** Supabase (après avoir lié le projet) :

```powershell
supabase secrets set OPENAI_API_KEY=sk-...
```

Pour vérifier (les valeurs ne s’affichent pas) :

```bash
supabase secrets list
```

---

## 6. Déployer l’Edge Function

```bash
supabase functions deploy analyze-quest-proof
```

Déploiement de toutes les functions :

```bash
supabase functions deploy
```

L’URL de la function sera :

`https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof`

---

## 7. Tester l’Edge Function (optionnel)

Avec la clé anon du projet (Dashboard → Settings → API → anon key) :

```bash
curl -i --location --request POST 'https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof' \
  --header 'Authorization: Bearer VOTRE_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"image_base64":"/9j/4AAQ...","quest_title":"Ranger ma chambre","quest_category":"Maison"}'
```

Réponse attendue (ex.) : `{"score":82,"explanation":"..."}`.

---

## 8. Configurer l’app Flutter

Dans le fichier **.env** à la racine du projet (à côté de `pubspec.yaml`), ajouter :

```env
SUPABASE_URL=https://VOTRE_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ...
VALIDATION_AI_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof
```

- Si **VALIDATION_AI_URL** est défini et non vide, l’app utilisera **ApiValidationAIService** (vraie IA).
- Sinon, elle utilisera **MockValidationAIService** (dév / tests sans backend).

L’app envoie déjà `Authorization: Bearer SUPABASE_ANON_KEY` pour les appels à l’Edge Function (JWT vérifié côté Supabase).

---

## 9. Développement local (optionnel)

Pour tester la function en local :

```bash
supabase start
supabase functions serve analyze-quest-proof
```

Créer un fichier **supabase/.env.local** (non versionné) avec :

```env
OPENAI_API_KEY=sk-...
```

Puis tester :

```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/analyze-quest-proof' \
  --header 'Authorization: Bearer VOTRE_ANON_KEY_LOCAL' \
  --header 'Content-Type: application/json' \
  --data '{"image_base64":"...","quest_title":"Test","quest_category":"Maison"}'
```

(`supabase status` affiche la clé anon locale.)

---

## 10. Résumé des commandes

| Action | Commande |
|--------|----------|
| Lier le projet | `supabase link --project-ref VOTRE_PROJECT_ID` |
| Définir la clé OpenAI | `supabase secrets set OPENAI_API_KEY=sk-...` |
| Déployer la function | `supabase functions deploy analyze-quest-proof` |
| Servir en local | `supabase functions serve analyze-quest-proof` |

---

## 11. Fichiers modifiés côté Flutter

- **lib/config/supabase_config.dart** : getter `validationAiUrl` (optionnel).
- **lib/domain/services/api_validation_ai_service.dart** : support de `authToken` pour `Authorization: Bearer`.
- **lib/ui/pages/quest/quest_validation_page.dart** : choix du service (API ou mock) selon `VALIDATION_AI_URL`.

Aucun changement nécessaire dans le reste de l’app : le format d’appel et de réponse est déjà aligné avec la doc [IA_ANALYSE_IMAGE.md](./IA_ANALYSE_IMAGE.md).
