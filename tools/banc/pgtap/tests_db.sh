#!/usr/bin/env bash
# Base jetable pour les tests pgTAP : émulation Supabase minimale + baseline
# reconstruite + toutes les migrations du dépôt, puis exécution des tests.
# Utilise le Postgres du banc (démarré par tools/banc/start.sh).
set -euo pipefail
cd "$(dirname "$0")"
source ../env.sh
REPO="$(cd ../../.. && pwd)"
P="psql -h 127.0.0.1 -p $PG_PORT -U postgres -v ON_ERROR_STOP=1 -q"
$P -d postgres -c "DROP DATABASE IF EXISTS pgtap" -c "CREATE DATABASE pgtap" 2>/dev/null
$P -d pgtap -f shim_supabase.sql >/dev/null
$P -d pgtap -f ../baseline_reconstruite.sql >/dev/null
for f in "$REPO"/supabase/migrations/*.sql; do $P -d pgtap -f "$f" >/dev/null 2>&1 || { echo "Migration en échec : $f"; $P -d pgtap -f "$f"; exit 1; }; done
cd "$REPO/supabase/tests/database"
pg_prove -h 127.0.0.1 -p "$PG_PORT" -U postgres -d pgtap *.test.sql
