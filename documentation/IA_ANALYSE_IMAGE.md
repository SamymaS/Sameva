# Analyse d’image par IA — Par où commencer

L’app utilise déjà un **service de validation** (`ValidationAIService`) et un **mock** (`MockValidationAIService`). Pour une vraie analyse d’image par IA, voici l’ordre recommandé.

---

## 1. Comprendre le flux actuel

- L’utilisateur prend une **photo** (ou vidéo) sur la **page de validation**.
- L’app appelle `ValidationAIService.analyzeProof(quest, imageBytes)`.
- Le service doit renvoyer : **score (0–100)** + **explication** (texte).  
  Seuil de validation : **70/100**.

Aujourd’hui, seul le **mock** est utilisé : pas d’appel réseau, pas d’IA réelle.

---

## 2. Choisir où fait tourner l’IA (recommandation)

**Ne pas appeler l’API d’IA directement depuis l’app Flutter** (clé API exposée, coût, sécurité).

Mettre l’analyse côté **backend** :

| Option | Avantage | À faire |
|--------|----------|--------|
| **Supabase Edge Function** | Déjà dans ton stack, une seule plateforme | Créer une Edge Function qui reçoit image + contexte quête, appelle l’IA, renvoie `{ score, explanation }`. |
| **Backend perso** (Node, Python, etc.) | Contrôle total | Exposer une route POST qui fait la même chose. |
| **Firebase Cloud Functions** | Si tu utilises déjà Firebase | Idem : une fonction qui reçoit l’image, appelle l’IA, renvoie le résultat. |

Recommandation : **Supabase Edge Function** (tu utilises déjà Supabase).

---

## 3. Choisir le modèle IA (vision)

- **OpenAI GPT-4 Vision** : très adapté (image + prompt texte → score + explication). Payant, simple à intégrer.
- **Google Cloud Vision API** : détection d’objets/labels ; tu peux ensuite comparer avec le titre/catégorie de la quête. Autre option si tu es déjà sur GCP.
- **Modèle open source (local ou API)** : plus technique, possible si tu veux tout maîtriser.

Pour démarrer rapidement : **GPT-4 Vision** derrière une Edge Function.

---

## 4. Étapes concrètes (ordre conseillé)

### Étape A — Backend (Supabase Edge Function)

1. Créer une **Edge Function** Supabase (ex. `analyze-quest-proof`).
2. Elle reçoit en **POST** :
   - **image** : base64 (ou multipart).
   - **quest_title** : string.
   - **quest_category** : string.
3. Dans la fonction :
   - Décoder l’image, appeler l’API **OpenAI Vision** (ou autre) avec un prompt du type :  
     *“Cette image prouve-t-elle que la tâche « [quest_title] » (catégorie [quest_category]) a été réalisée ? Réponds en JSON : { \"score\": 0-100, \"explanation\": \"...\" }. Sois strict : 70+ seulement si la preuve est convaincante.”*
   - Récupérer `score` et `explanation`, les renvoyer en JSON.
4. Stocker la **clé API OpenAI** (ou autre) dans les **secrets** Supabase, pas dans le code.

### Étape B — Flutter : appeler ton backend

1. Ajouter le package **`http`** dans `pubspec.yaml` (pour les appels HTTP).
2. Utiliser le service **`ApiValidationAIService`** (déjà préparé dans le projet) :
   - Il envoie en POST l’image (base64) + titre/catégorie de la quête vers l’URL de ton Edge Function (ou de ton backend).
   - Il lit la réponse JSON `{ score, explanation }` et retourne un `ValidationResult`.
3. Dans l’app, **remplacer** `MockValidationAIService()` par `ApiValidationAIService(baseUrl: '...')` (ou injecter l’URL via config / .env).

### Étape C — Config et sécurité

- Mettre l’**URL de l’Edge Function** (ou du backend) dans un fichier **`.env`** (ou config Supabase) et la charger au démarrage.
- Ne jamais mettre la clé API OpenAI dans le client : uniquement dans les **secrets** de l’Edge Function (ou variables d’environnement du serveur).

---

## 5. Format d’échange suggéré (backend ↔ app)

**Requête POST** (body JSON) :

```json
{
  "image_base64": "<données image en base64>",
  "quest_title": "Ranger ma chambre",
  "quest_category": "Maison"
}
```

**Réponse** (JSON) :

```json
{
  "score": 82,
  "explanation": "La photo montre une pièce rangée, lit fait, bureau dégagé. Cohérent avec la quête."
}
```

L’app attend exactement ces deux champs pour construire `ValidationResult` et afficher le score + l’explication.

---

## 6. Fichiers utiles dans le projet

- **`lib/domain/services/validation_ai_service.dart`**  
  Définition de `ValidationAIService` et du **mock**. C’est ici qu’on ajoute / utilise une implémentation « réelle ».

- **`lib/domain/services/api_validation_ai_service.dart`**  
  Squelette du service qui appelle **ton backend** (Edge Function ou autre). À brancher sur l’URL et le format ci‑dessus.

- **`lib/ui/pages/quest/quest_validation_page.dart`**  
  Utilise le service (mock ou API) ; aucun changement majeur une fois le bon service injecté.

---

## 7. Résumé « par où commencer »

1. **Décider** : Supabase Edge Function + OpenAI Vision (ou autre modèle).
2. **Créer** l’Edge Function qui reçoit image + contexte quête et renvoie `score` + `explanation`.
3. **Tester** l’Edge Function avec un outil (Postman, curl) avant de toucher à Flutter.
4. **Dans Flutter** : ajouter `http`, configurer `ApiValidationAIService` avec l’URL, et l’utiliser à la place du mock.
5. **Garder** le mock pour le dev hors ligne ou les tests.

Une fois l’Edge Function en place et l’URL configurée, le reste est surtout du branchement dans `ApiValidationAIService` et le choix du service (mock vs API) au lancement de l’app.
