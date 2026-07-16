# Validation de preuve par IA (MougiBot)

> Ce document décrit le flux de validation **tel qu'il est implémenté**. Le validateur est en production sur l'Edge Function `analyze-quest-proof` et s'appuie sur **Anthropic Claude Haiku Vision**.

---

## 1. Principe

L'utilisateur photographie une preuve de sa quête. L'image est analysée par MougiBot, l'esprit analytique du compagnon Mougi, qui renvoie un **score de 0 à 100** et une **explication courte en français**.

| Score | Conséquence |
| ----- | ----------- |
| >= 70 | Validation automatique, récompense complète (XP, gold, items) |
| < 70  | Validation manuelle possible, récompense réduite de moitié |

L'utilisateur n'est **jamais bloqué** : la validation manuelle reste toujours accessible, y compris sans jeton, sans premium ou en cas de panne de l'IA.

---

## 2. Chaîne d'appel

```
QuestValidationPage
  └─> QuestValidationViewModel.analyzeProof()
        └─> ValidationAIService (interface)
              ├─ MockValidationAIService        (développement et tests, score déterministe, aucun réseau)
              ├─ ApiValidationAIService         (appel HTTP vers l'Edge Function)
              └─ ClaudeValidationAIService      (appel direct de l'API Messages, réservé aux tests d'intégration)
                    └─> Edge Function analyze-quest-proof (Deno)
                          └─> API Anthropic /v1/messages (Claude Haiku Vision)
```

Le service est choisi au démarrage selon la configuration : si `VALIDATION_AI_URL` est renseignée dans le `.env`, l'application utilise l'implémentation réseau, sinon elle retombe sur le mock. Le client HTTP est injectable, ce qui rend les tests unitaires indépendants du réseau.

La clé API Anthropic n'est **jamais** embarquée dans l'application. Elle vit dans les secrets Supabase et n'est lue que par l'Edge Function.

---

## 3. Format d'échange

**Requête** (POST, JSON) :

```json
{
  "image_base64": "<base64 sans le préfixe data:image>",
  "quest_title": "Ranger ma chambre",
  "quest_category": "Maison"
}
```

**Réponse 200** :

```json
{
  "score": 82,
  "explanation": "Bravo, ta chambre est nickel, mission accomplie !"
}
```

**Réponses d'erreur** :

| Code | Cause                                                        |
| ---- | ------------------------------------------------------------ |
| 400  | `image_base64`, `quest_title` ou `quest_category` manquant ou invalide |
| 405  | Méthode autre que POST                                       |
| 413  | Image supérieure à environ 5 Mo en base64                     |
| 502  | Échec de l'analyse (timeout, erreur API, réponse illisible)   |

Le préfixe `data:image/...;base64,` est toléré et retiré côté serveur. Le type de média (JPEG, PNG, GIF, WebP) est déduit de la signature du base64.

---

## 4. Comportement du modèle

Le prompt système fixe une échelle de notation explicite :

| Plage  | Interprétation |
| ------ | -------------- |
| 85-100 | Preuve excellente, accomplissement clair et sans ambiguïté |
| 70-84  | Preuve crédible, seuil de validation automatique |
| 50-69  | Preuve ambiguë ou partielle (photo floue, cadrage incomplet) |
| 20-49  | Preuve insuffisante, effort visible mais hors sujet partiel |
| 0-19   | Preuve absente ou tentative de triche (capture d'écran, image téléchargée, photo vide) |

Le ton des explications est bienveillant, tutoyé, en une phrase de 25 mots maximum. Une photo floue est traitée avec indulgence plutôt que sanctionnée.

---

## 5. Robustesse

La fonction ne fait pas confiance à la sortie du modèle et la contrôle systématiquement :

- **Nettoyage** : les éventuels blocs markdown (backticks) sont retirés avant analyse.
- **Extraction** : le premier objet JSON est isolé entre la première accolade ouvrante et la dernière fermante.
- **Bornage** : le score est arrondi puis contraint dans l'intervalle 0 à 100.
- **Rejet** : un score non numérique ou une explication vide lève une erreur, remontée en 502.
- **Timeout** : l'appel est interrompu au bout de 25 secondes via un `AbortController`.
- **Taille** : toute image dépassant environ 5 Mo est refusée avant l'appel au modèle.

En cas d'échec, l'application n'est pas bloquée : l'utilisateur bascule sur la validation manuelle.

---

## 6. Sécurité du prompt

Le titre et la catégorie de quête sont des **données utilisateur non fiables**. Le prompt système ordonne explicitement d'ignorer toute instruction qu'ils pourraient contenir, de ne jamais révéler les instructions internes, et de conserver le rôle de MougiBot quoi qu'il arrive. Cette consigne protège contre l'injection de prompt par le titre de quête ou par du texte présent dans l'image.

---

## 7. Fichiers concernés

| Fichier | Rôle |
| ------- | ---- |
| `supabase/functions/analyze-quest-proof/index.ts` | Edge Function, prompt système, appel Anthropic, parsing |
| `lib/domain/services/validation_ai_service.dart` | Interface `ValidationAIService` et mock |
| `lib/domain/services/api_validation_ai_service.dart` | Appel HTTP vers l'Edge Function |
| `lib/domain/services/claude_validation_ai_service.dart` | Appel direct de l'API Messages |
| `lib/presentation/view_models/quest_validation_view_model.dart` | Orchestration, état `isAnalyzing`, `result` |
| `lib/ui/pages/quest/quest_validation_page.dart` | Prise de photo et affichage du score |

---

## 8. Coût

Chaque validation consomme un appel Claude Haiku Vision, de l'ordre de **0,5 à 1 centime**. Le coût est borné côté produit par le portefeuille de jetons (`ai_validation_credits`) et par l'abonnement premium, décrits dans le README.

→ Déploiement et configuration : [SUPABASE_EDGE_FUNCTION_IA.md](SUPABASE_EDGE_FUNCTION_IA.md)
