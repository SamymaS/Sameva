# Sprint 0 puis déploiement du Sprint 1

Procédure à suivre sur le PC de dev (Windows, PowerShell), dans l'ordre. Durée
estimée : 1 h 30. Rien n'est irréversible avant l'étape 8.

Prérequis : Docker Desktop lancé, Supabase CLI à jour (`scoop update supabase`
ou `npm i -g supabase`), Deno 2, Flutter 3.41.9.

## 1. Réactiver le projet

Le projet `mgddxrysvjlpfejbmfly` est en pause (offre gratuite). Dashboard
Supabase → projet → **Restore project**. Attendre le statut « Healthy ».

## 2. Lier le dépôt et sauvegarder l'existant

```powershell
supabase login
supabase link --project-ref mgddxrysvjlpfejbmfly
supabase db dump -f supabase/backups/2026-10_prod_schema.sql
supabase db dump --data-only -f supabase/backups/2026-10_prod_data.sql
```

`supabase/backups/` est ignoré par Git : ces fichiers contiennent des données
personnelles, ils ne doivent jamais être commités.

## 3. Créer la baseline

Les tables `quests`, `users`, `companions`, `user_inventory`, `user_equipment`,
`items`, `transactions` ont été créées depuis le dashboard : aucune migration
ne les décrit, donc une base vide ne peut pas rejouer l'historique. On remplace
les anciennes migrations par une photographie du schéma actuel.

```powershell
New-Item -ItemType Directory supabase/migrations_archive
git mv supabase/migrations/202602*.sql supabase/migrations_archive/
git mv supabase/migrations/202605*.sql supabase/migrations_archive/
git mv supabase/migrations/202606*.sql supabase/migrations_archive/
supabase db dump -f supabase/migrations/20260101000000_baseline.sql
```

Les migrations `202611020001` à `202611020004` (Sprint 1) restent en place,
après la baseline.

## 4. Mettre à jour l'historique des migrations du projet distant

```powershell
supabase migration repair --status reverted 20260224000000 20260512100000 20260513120000 20260516000000 20260517000000 20260616000000 20260616000001 20260616000002
supabase migration repair --status applied 20260101000000
supabase migration list
```

`migration list` doit montrer la baseline appliquée et les quatre migrations
du Sprint 1 en attente.

## 5. Tester en local, sur la vraie baseline

```powershell
supabase start
supabase db reset          # baseline + Sprint 1
supabase test db           # attendu : 177 tests, tous verts
cd supabase/functions/analyze-quest-proof
deno test --node-modules-dir=none --allow-net --allow-read index.test.ts dhash.test.ts
$env:SAMEVA_TEST_DB_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
deno test --node-modules-dir=none --allow-env --allow-net --allow-read --allow-sys integration.test.ts
cd ../../..
flutter analyze
flutter test
```

Si un test pgTAP échoue ici alors qu'il passait chez moi, c'est que la vraie
baseline diffère de ma reconstitution (type d'une colonne de `quests`, par
exemple). C'est exactement le rôle de cette étape : corriger avant la prod.

## 6. Recette sur le staging (NAS)

Voir `infra/nas/README.md`. Appliquer les migrations sur le staging, déployer
les fonctions, installer l'APK de test et dérouler la démo de validation du
document d'architecture (section « Sprint 1 livré »).

## 7. Commits

Commits suggérés (dans l'ordre) :

1. `chore(db): baseline du schéma et archivage des migrations historiques`
2. `feat(db): fondations de l'économie serveur (registre, game_config)`
3. `feat(db): quêtes autoritaires et règles quotidiennes`
4. `feat(db): Oracle autoritaire, défi de capture et empreinte perceptuelle`
5. `feat(db): gacha serveur, passerelles transitoires et verrouillage des écritures`
6. `test(db): suite pgTAP du Sprint 1 et non-régression sécurité`
7. `feat(oracle): Edge Function analyze-quest-proof autoritaire et ses tests`
8. `refactor(client): GameApi et état joueur lu depuis le serveur`
9. `refactor(client): parcours quête, Oracle, quotidien, gacha et marché via les RPC`
10. `feat(client): défi de capture sur l'écran de preuve`
11. `ci: tests backend et déploiement manuel des fonctions`
12. `docs: ADR 0005 et 0006, runbook Sprint 0`

## 8. Mise en production (irréversible)

```powershell
supabase db push
```

Puis, dans l'éditeur SQL du dashboard, `supabase/scripts/reinitialiser_economie_recette.sql`
(remet à zéro les soldes des comptes de test, qui ne sont pas fiables).

Ensuite GitHub → Actions → **Deploy backend** → Run workflow. Le déploiement
des fonctions n'est plus automatique : il doit toujours suivre `db push`.

Vérifier que `ANTHROPIC_API_KEY` est bien dans les secrets des Edge Functions.

## 9. Publier l'app

Passer la version à `1.1.0+N` dans `pubspec.yaml` et publier l'APK. L'ancien
APK ne fonctionne plus avec le serveur : prévenir les testeurs.

## 10. Contrôle final

```powershell
supabase db diff --linked   # doit être vide
```
