# Configuration du banc d'essai local (valeurs de développement, jamais de prod).
export BANC_DIR="${BANC_DIR:-/tmp/sameva-banc}"
export BANC_BIN="${BANC_BIN:-$HOME/.cache/sameva-banc}"
export PG_BIN="${PG_BIN:-/usr/lib/postgresql/16/bin}"
export PG_PORT=54330
export PG_HOST=127.0.0.1
export GATEWAY_PORT=54321          # URL publique du banc : http://127.0.0.1:54321
export POSTGREST_PORT=54331
export GOTRUE_PORT=54332
export FN_PORT_BASE=54340          # une Edge Function par port à partir d'ici
# Secret JWT de développement (même valeur que le `supabase start` officiel).
export JWT_SECRET="super-secret-jwt-token-with-at-least-32-characters-long"
export POSTGREST_VERSION=v12.2.3
export GOTRUE_VERSION=v2.180.0
