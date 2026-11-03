# Tester l'app sur Android avec un Supabase local

Validé le 2026-10-30 sur le PC de dev (Windows, émulateur Pixel 7, Docker
Desktop) : migrations et 190 tests pgTAP verts sur la vraie pile Supabase
(Postgres 17), parcours invité, création de quête, caméra, défi, Oracle simulé,
récompenses et lien profond.

## 1. Backend local

```powershell
npx supabase start                      # applique supabase/migrations
npx supabase test db                    # pgTAP sur la vraie pile
Get-Content tools\banc\reglages_banc.sql | docker exec -i supabase_db_<project_id> psql -U postgres
"ORACLE_VISION=simulation" | Set-Content supabase\functions\.env.local -Encoding ascii
npx supabase functions serve --env-file supabase\functions\.env.local
```

- Tant que la baseline du Sprint 0 n'existe pas, copier
  `tools/banc/baseline_reconstruite.sql` en
  `supabase/migrations/20260101000000_baseline_banc.sql` dans la copie de test
  (jamais dans le dépôt).
- `reglages_banc.sql` autorise la validation déclarative immédiate (dev seulement).
- L'Oracle simulé ne s'active que si l'URL Supabase est locale (`kong` compris).

## 2. App sur l'émulateur

```powershell
# config/emu.json (ignoré par Git) : clé anon de « npx supabase status -o env »
# { "SAMEVA_ENV": "emulateur", "SUPABASE_URL": "http://127.0.0.1:54321",
#   "SUPABASE_ANON_KEY": "...", "GOOGLE_WEB_CLIENT_ID": "emulateur-local" }
adb reverse tcp:54321 tcp:54321
flutter build apk --debug --dart-define-from-file=config\emu.json
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

- Lancer l'émulateur avec `-camera-back virtualscene` : l'appareil photo
  système fonctionne, la photo prise est jugée « preuve valable » par la
  simulation.
- Lien profond : `adb shell am start -a android.intent.action.VIEW -d "sameva://app/quete/<id>" com.sameva.app`.
- Pilotage sans écran : `adb shell uiautomator dump` lit les libellés
  d'accessibilité (constat Q17 : l'arbre peut rester figé après une fiche).

## 3. Pièges rencontrés

- Deux copies du dépôt avec le même `project_id` partagent les mêmes
  conteneurs : changer `project_id` dans la copie de test.
- Sous Windows PowerShell 5, `Set-Content -Encoding utf8` ajoute un BOM et
  `Get-Content` lit en ANSI : écrire avec `[IO.File]::WriteAllText(..., UTF8Encoding($false))`.
