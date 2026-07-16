# Edge Functions Supabase, déploiement et configuration

Ce guide décrit le déploiement des Edge Functions de Sameva. Elles sont écrites en TypeScript pour le runtime Deno et hébergent tout ce qui ne doit pas vivre dans le client : les clés secrètes, la logique de paiement et la suppression de compte.

Références : [Quickstart](https://supabase.com/docs/guides/functions/quickstart) et [Overview](https://supabase.com/docs/guides/functions).

---

## 1. Les cinq fonctions

| Fonction | Rôle | `verify_jwt` |
| -------- | ---- | ------------ |
| `analyze-quest-proof` | Valide une preuve photo via Claude Haiku Vision, renvoie `{ score, explanation }` | `true` |
| `suggest-quests` | Génère des suggestions de quêtes via Claude | `true` |
| `create-checkout-session` | Ouvre une session Stripe Checkout pour l'abonnement premium | `true` |
| `stripe-webhook` | Reçoit les événements Stripe et met à jour l'entitlement premium | `false` (authentifié par signature HMAC) |
| `delete-account` | Supprime le compte de façon conforme au RGPD | `true` |

`stripe-webhook` est la seule fonction sans vérification de JWT, car Stripe appelle sans session Supabase. Elle est protégée par la vérification cryptographique de la signature de l'événement.

---

## 2. Prérequis

- **Supabase CLI** ([installation](https://supabase.com/docs/guides/cli))
- Un **projet Supabase** créé sur [database.new](https://database.new)
- Une **clé API Anthropic** ([console.anthropic.com](https://console.anthropic.com))
- Un **compte Stripe** (mode test suffisant) pour les fonctions de paiement

### Installation de la CLI sur Windows

Si la commande `supabase` n'est pas reconnue, passer par npm et préfixer par `npx` :

```powershell
npm install supabase --save-dev
npx supabase login
npx supabase link --project-ref VOTRE_PROJECT_REF
```

Alternative avec Scoop :

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
iwr -useb get.scoop.sh | iex
scoop install supabase
```

---

## 3. Lier le projet

Le **Reference ID** se trouve dans Dashboard, Settings, General.

```bash
supabase login
supabase link --project-ref VOTRE_PROJECT_REF
```

---

## 4. Configurer les secrets

Les clés ne sont **jamais** dans le dépôt ni dans le bundle de l'application. Elles vivent dans les secrets Supabase et ne sont lisibles que par les Edge Functions.

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
```

Vérification (les valeurs ne s'affichent pas) :

```bash
supabase secrets list
```

> **Sécurité** : ne jamais committer une clé ni la coller dans un chat. Une clé exposée doit être révoquée immédiatement depuis la console du fournisseur, puis régénérée.

`SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont injectées automatiquement par la plateforme dans l'environnement des fonctions : il est inutile de les déclarer.

---

## 5. Déployer

Une fonction précise :

```bash
supabase functions deploy analyze-quest-proof
```

Toutes les fonctions :

```bash
supabase functions deploy
```

L'URL suit toujours le motif :

```
https://VOTRE_PROJECT_REF.supabase.co/functions/v1/<nom-de-la-fonction>
```

---

## 6. Tester

```bash
curl -i --location --request POST 'https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof' \
  --header 'Authorization: Bearer VOTRE_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"image_base64":"/9j/4AAQ...","quest_title":"Ranger ma chambre","quest_category":"Maison"}'
```

Réponse attendue : `{"score":82,"explanation":"..."}`.

Sur Windows, utiliser `curl.exe` pour éviter l'alias PowerShell `Invoke-WebRequest`.

---

## 7. Configurer l'application Flutter

Dans le fichier `.env` à la racine (à côté de `pubspec.yaml`) :

```env
SUPABASE_URL=https://VOTRE_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=eyJ...
VALIDATION_AI_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/analyze-quest-proof
SUGGEST_QUESTS_URL=https://VOTRE_PROJECT_REF.supabase.co/functions/v1/suggest-quests
```

Si `VALIDATION_AI_URL` est vide ou absente, l'application utilise `MockValidationAIService` et fonctionne sans backend IA, ce qui est le comportement attendu en développement et en intégration continue.

L'application envoie le JWT de la session dans l'en-tête `Authorization`, vérifié par Supabase avant l'exécution de la fonction.

---

## 8. Développement local

```bash
supabase start
supabase functions serve analyze-quest-proof
```

Créer `supabase/.env.local` (non versionné) :

```env
ANTHROPIC_API_KEY=sk-ant-...
```

`supabase status` affiche la clé anon locale à utiliser pour les tests.

---

## 9. Webhook Stripe

Après le déploiement de `stripe-webhook`, déclarer l'endpoint côté Stripe (Dashboard, Developers, Webhooks) :

```
https://VOTRE_PROJECT_REF.supabase.co/functions/v1/stripe-webhook
```

Récupérer le secret de signature généré et le pousser dans `STRIPE_WEBHOOK_SECRET`. Sans lui, la fonction rejette tous les événements.

---

## 10. Résumé des commandes

| Action | Commande |
| ------ | -------- |
| Lier le projet | `supabase link --project-ref VOTRE_PROJECT_REF` |
| Définir la clé Anthropic | `supabase secrets set ANTHROPIC_API_KEY=sk-ant-...` |
| Déployer une fonction | `supabase functions deploy analyze-quest-proof` |
| Déployer toutes les fonctions | `supabase functions deploy` |
| Servir en local | `supabase functions serve analyze-quest-proof` |
| Lister les secrets | `supabase secrets list` |

→ Fonctionnement détaillé du validateur : [IA_ANALYSE_IMAGE.md](IA_ANALYSE_IMAGE.md)
