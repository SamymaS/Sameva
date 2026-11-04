#!/usr/bin/env bash
# =============================================================================
# Valide tout le projet, comme le ferait la CI, plus les parcours réels :
#   1. analyse statique et tests Flutter
#   2. tests pgTAP (règles du jeu et droits) sur une base jetable
#   3. tests de l'Edge Function Oracle (unitaires + intégration sur la base)
#   4. banc complet (auth, API, fonctions) : test de fumée API
#   5. app web construite et pilotée comme un joueur (Playwright)
# Usage : tools/banc/tout_tester.sh [--sans-app]
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")/../.."
REPO="$(pwd)"
source tools/banc/env.sh
export PATH="/opt/flutter/bin:$HOME/.npm-global/bin:$PATH"
RESULTATS=()
etape() { # nom, commande
  local nom="$1"; shift
  echo -e "\n━━━ $nom"
  if "$@"; then RESULTATS+=("ok      $nom"); else RESULTATS+=("ÉCHEC   $nom"); fi
}

etape "Banc (Postgres, GoTrue, PostgREST, fonctions)" tools/banc/start.sh
etape "Flutter : analyse statique" flutter analyze
etape "Flutter : tests" flutter test
etape "Base : tests pgTAP" tools/banc/pgtap/tests_db.sh
etape "Oracle : tests unitaires" bash -c "cd supabase/functions/analyze-quest-proof && deno test --node-modules-dir=none --allow-net --allow-read index.test.ts dhash.test.ts"
etape "Oracle : intégration sur la base" bash -c "cd supabase/functions/analyze-quest-proof && SAMEVA_TEST_DB_URL=postgresql://postgres@127.0.0.1:$PG_PORT/pgtap deno test --node-modules-dir=none --allow-env --allow-net --allow-read --allow-sys integration.test.ts"
etape "API : test de fumée" deno run -A tools/banc/fumee.ts
if [ "${1:-}" != "--sans-app" ]; then
  etape "App web : construction" tools/banc/app.sh
  etape "App web : parcours joueur" bash -c "cd tools/banc/e2e && [ -d node_modules ] || npm ci --silent; node parcours.mjs"
fi

echo -e "\n━━━ Bilan"
printf '%s\n' "${RESULTATS[@]}"
! printf '%s\n' "${RESULTATS[@]}" | grep -q "^ÉCHEC"
