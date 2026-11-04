#!/usr/bin/env bash
# Construit l'app Flutter en version web, branchée sur le banc local, et la
# sert sur http://127.0.0.1:8080. Usage : tools/banc/app.sh [--no-build]
set -euo pipefail
cd "$(dirname "$0")/../.."
source tools/banc/env.sh
export PATH="/opt/flutter/bin:$PATH"
if [ "${1:-}" != "--no-build" ]; then
  # Configuration compilée (dart-define) avec les clés de DÉVELOPPEMENT du banc.
  python3 - "$BANC_DIR/banc.env" "$BANC_DIR/config-banc.json" <<'PY'
import json, sys
env = dict(l.strip().split("=", 1) for l in open(sys.argv[1]) if "=" in l)
json.dump({"SAMEVA_ENV": "banc", "SUPABASE_URL": env["SUPABASE_URL"],
           "SUPABASE_ANON_KEY": env["SUPABASE_ANON_KEY"], "GOOGLE_WEB_CLIENT_ID": "banc-local"},
          open(sys.argv[2], "w"))
PY
  flutter build web --release --no-tree-shake-icons --dart-define-from-file="$BANC_DIR/config-banc.json" \
    > "$BANC_DIR/logs/flutter-build.log" 2>&1 || { tail -30 "$BANC_DIR/logs/flutter-build.log"; exit 1; }
fi
if [ -f "$BANC_DIR/app.pid" ] && kill -0 "$(cat "$BANC_DIR/app.pid")" 2>/dev/null; then kill "$(cat "$BANC_DIR/app.pid")"; fi
nohup python3 -m http.server 8080 --bind 127.0.0.1 --directory build/web > "$BANC_DIR/logs/app.log" 2>&1 &
echo $! > "$BANC_DIR/app.pid"
echo "App web : http://127.0.0.1:8080"
