#!/usr/bin/env bash
# =============================================================================
# Banc d'essai local Sameva : un mini-Supabase complet sans Docker.
#   Postgres 16 + GoTrue (auth) + PostgREST (API) + Edge Functions (Deno)
#   derrière une passerelle unique : http://127.0.0.1:54321
#
# Usage : tools/banc/start.sh [--reset]
#   --reset : repart d'une base vierge (sinon, réutilise la base existante).
# Arrêt   : tools/banc/stop.sh
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
HERE="$(pwd)"
REPO="$(cd ../.. && pwd)"
source ./env.sh
mkdir -p "$BANC_DIR/logs" "$BANC_BIN"

# ─── Binaires ────────────────────────────────────────────────────────────────
if [ ! -x "$BANC_BIN/postgrest" ]; then
  echo "Téléchargement de PostgREST $POSTGREST_VERSION"
  curl -sSL "https://github.com/PostgREST/postgrest/releases/download/$POSTGREST_VERSION/postgrest-$POSTGREST_VERSION-linux-static-x64.tar.xz" \
    | tar xJ -C "$BANC_BIN"
fi
if [ ! -x "$BANC_BIN/gotrue/auth" ]; then
  echo "Téléchargement de GoTrue $GOTRUE_VERSION"
  mkdir -p "$BANC_BIN/gotrue"
  curl -sSL "https://github.com/supabase/auth/releases/download/$GOTRUE_VERSION/auth-$GOTRUE_VERSION-x86.tar.gz" \
    | tar xz -C "$BANC_BIN/gotrue"
fi

# ─── Postgres ────────────────────────────────────────────────────────────────
PGDATA="$BANC_DIR/pg"
if [ "${1:-}" = "--reset" ] && [ -d "$PGDATA" ]; then
  "$HERE/stop.sh" >/dev/null 2>&1 || true
  rm -rf "$PGDATA"
fi
RUN_AS=""
[ "$(id -u)" = "0" ] && RUN_AS="su postgres -c"
pg() { if [ -n "$RUN_AS" ]; then su postgres -c "$*"; else bash -c "$*"; fi; }
FRESH=0
if [ ! -d "$PGDATA" ]; then
  mkdir -p "$PGDATA" && [ -n "$RUN_AS" ] && chown -R postgres "$BANC_DIR"
  pg "$PG_BIN/initdb -D $PGDATA -U postgres -A trust -E UTF8 --locale=C.UTF-8 >/dev/null"
  FRESH=1
fi
[ -n "$RUN_AS" ] && chown -R postgres "$BANC_DIR"
if ! pg "$PG_BIN/pg_ctl -D $PGDATA status" >/dev/null 2>&1; then
  pg "$PG_BIN/pg_ctl -D $PGDATA -o '-p $PG_PORT -h 127.0.0.1 -k $BANC_DIR' -l $BANC_DIR/logs/postgres.log start" >/dev/null
  sleep 2
fi
PSQL="psql -h 127.0.0.1 -p $PG_PORT -U postgres -v ON_ERROR_STOP=1 -q"

if [ "$FRESH" = "1" ]; then
  echo "Base vierge : rôles, auth, baseline, migrations"
  $PSQL -d postgres -c "CREATE DATABASE banc"
  $PSQL -d banc -f roles.sql
  # Schéma auth : migrations officielles de GoTrue.
  (cd "$BANC_BIN/gotrue" && GOTRUE_DB_DRIVER=postgres \
     DATABASE_URL="postgres://supabase_auth_admin:banc@127.0.0.1:$PG_PORT/banc?search_path=auth" \
     GOTRUE_JWT_SECRET="$JWT_SECRET" API_EXTERNAL_URL="http://127.0.0.1:$GATEWAY_PORT/auth/v1" \
     GOTRUE_SITE_URL="http://127.0.0.1:8080" ./auth migrate > "$BANC_DIR/logs/gotrue-migrate.log" 2>&1)
  $PSQL -d banc -f baseline_reconstruite.sql
  for f in "$REPO"/supabase/migrations/*.sql; do
    $PSQL -d banc -f "$f" > /dev/null
  done
  $PSQL -d banc -f reglages_banc.sql
  $PSQL -d banc -c "NOTIFY pgrst, 'reload schema'"
fi

# ─── Clés ────────────────────────────────────────────────────────────────────
eval "$(deno run --quiet --allow-env keys.ts)"
export ANON_KEY SERVICE_ROLE_KEY
cat > "$BANC_DIR/banc.env" <<ENV
SUPABASE_URL=http://127.0.0.1:$GATEWAY_PORT
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
ENV

start_bg() { # nom, commande
  local name="$1"; shift
  if [ -f "$BANC_DIR/$name.pid" ] && kill -0 "$(cat "$BANC_DIR/$name.pid")" 2>/dev/null; then return; fi
  nohup bash -c "$*" > "$BANC_DIR/logs/$name.log" 2>&1 &
  echo $! > "$BANC_DIR/$name.pid"
}

# ─── PostgREST ───────────────────────────────────────────────────────────────
start_bg postgrest "PGRST_DB_URI='postgres://authenticator:banc@127.0.0.1:$PG_PORT/banc' \
  PGRST_DB_SCHEMAS=public PGRST_DB_ANON_ROLE=anon PGRST_JWT_SECRET='$JWT_SECRET' \
  PGRST_SERVER_PORT=$POSTGREST_PORT PGRST_SERVER_HOST=127.0.0.1 PGRST_DB_CHANNEL_ENABLED=true \
  exec $BANC_BIN/postgrest"

# ─── GoTrue ──────────────────────────────────────────────────────────────────
start_bg gotrue "cd $BANC_BIN/gotrue && GOTRUE_DB_DRIVER=postgres \
  DATABASE_URL='postgres://supabase_auth_admin:banc@127.0.0.1:$PG_PORT/banc?search_path=auth' \
  GOTRUE_JWT_SECRET='$JWT_SECRET' GOTRUE_JWT_EXP=3600 GOTRUE_JWT_AUD=authenticated \
  GOTRUE_JWT_DEFAULT_GROUP_NAME=authenticated GOTRUE_JWT_ADMIN_ROLES=service_role \
  API_EXTERNAL_URL='http://127.0.0.1:$GATEWAY_PORT/auth/v1' GOTRUE_SITE_URL='http://127.0.0.1:8080' \
  GOTRUE_URI_ALLOW_LIST='*' GOTRUE_DISABLE_SIGNUP=false GOTRUE_MAILER_AUTOCONFIRM=true \
  GOTRUE_EXTERNAL_EMAIL_ENABLED=true GOTRUE_EXTERNAL_ANONYMOUS_USERS_ENABLED=true \
  GOTRUE_RATE_LIMIT_ANONYMOUS_USERS=1000 GOTRUE_RATE_LIMIT_EMAIL_SENT=1000 \
  GOTRUE_API_HOST=127.0.0.1 PORT=$GOTRUE_PORT exec ./auth"

# ─── Edge Functions ──────────────────────────────────────────────────────────
FUNCTION_PORTS="{"
i=0
for fn in analyze-quest-proof delete-account suggest-quests; do
  port=$((FN_PORT_BASE + i)); i=$((i + 1))
  start_bg "fn-$fn" "cd '$REPO' && FN_PORT=$port FN_ENTRY='supabase/functions/$fn/index.ts' \
    SUPABASE_URL='http://127.0.0.1:$GATEWAY_PORT' SUPABASE_ANON_KEY='$ANON_KEY' \
    SUPABASE_SERVICE_ROLE_KEY='$SERVICE_ROLE_KEY' ORACLE_VISION=simulation \
    exec deno run --node-modules-dir=none --allow-net --allow-env --allow-read '$HERE/run_function.ts'"
  FUNCTION_PORTS+="\"$fn\":$port,"
done
FUNCTION_PORTS="${FUNCTION_PORTS%,}}"

# ─── Passerelle ──────────────────────────────────────────────────────────────
start_bg gateway "GATEWAY_PORT=$GATEWAY_PORT POSTGREST_PORT=$POSTGREST_PORT GOTRUE_PORT=$GOTRUE_PORT \
  FUNCTION_PORTS='$FUNCTION_PORTS' exec deno run --allow-net --allow-env '$HERE/gateway.ts'"

# ─── Attente ─────────────────────────────────────────────────────────────────
for _ in $(seq 1 60); do
  if curl -fs "http://127.0.0.1:$GATEWAY_PORT/auth/v1/health" >/dev/null 2>&1 \
     && curl -fs -H "apikey: $ANON_KEY" "http://127.0.0.1:$GATEWAY_PORT/rest/v1/" >/dev/null 2>&1; then
    echo "Banc prêt : http://127.0.0.1:$GATEWAY_PORT  (clés dans $BANC_DIR/banc.env)"
    exit 0
  fi
  sleep 1
done
echo "Le banc ne répond pas : voir $BANC_DIR/logs/" >&2
exit 1
