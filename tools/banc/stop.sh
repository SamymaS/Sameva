#!/usr/bin/env bash
# Arrête le banc d'essai local (les données sont conservées).
cd "$(dirname "$0")" && source ./env.sh
for f in "$BANC_DIR"/*.pid; do
  [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null; rm -f "$f"
done
if [ "$(id -u)" = "0" ]; then su postgres -c "$PG_BIN/pg_ctl -D $BANC_DIR/pg stop -m fast" 2>/dev/null
else "$PG_BIN/pg_ctl" -D "$BANC_DIR/pg" stop -m fast 2>/dev/null; fi
echo "Banc arrêté."
