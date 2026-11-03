#!/bin/sh
# =============================================================================
# Sauvegarde nocturne de la base de production Sameva vers le NAS.
# =============================================================================
# - pg_dump au format custom (restauration sélective possible), via Docker :
#   aucune installation de PostgreSQL sur le NAS.
# - Chiffrement AES-256 (openssl) : le NAS ne stocke jamais de données en clair.
# - Rétention : 30 sauvegardes quotidiennes + 12 mensuelles (le 1er du mois).
#
# Configuration (fichiers lisibles par root uniquement, chmod 600) :
#   /volume1/sameva/secrets/db_url        postgresql://postgres.<ref>:<mdp>@aws-0-eu-north-1.pooler.supabase.com:5432/postgres
#   /volume1/sameva/secrets/backup_key    phrase de chiffrement (à conserver AUSSI hors du NAS)
#
# Planification (TOS : Panneau de configuration > Tâches planifiées, ou crontab root) :
#   15 3 * * * /volume1/sameva/infra/sauvegarde_supabase.sh >> /volume1/sameva/logs/sauvegarde.log 2>&1
# =============================================================================
set -eu

BASE=/volume1/sameva
DEST="$BASE/sauvegardes"
SECRETS="$BASE/secrets"
PG_IMAGE=postgres:17-alpine
DATE=$(date +%Y-%m-%d)
FICHIER="$DEST/quotidien/sameva_$DATE.dump.enc"

mkdir -p "$DEST/quotidien" "$DEST/mensuel" "$BASE/logs"
umask 077

echo "[$(date -Iseconds)] Début de la sauvegarde"
docker run --rm -e DB_URL="$(cat "$SECRETS/db_url")" "$PG_IMAGE" \
  sh -c 'pg_dump --format=custom --no-owner --no-privileges "$DB_URL"' \
  | openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass "file:$SECRETS/backup_key" \
  > "$FICHIER.tmp"

# Un dump vide ou tronqué ne remplace jamais une bonne sauvegarde.
TAILLE=$(wc -c < "$FICHIER.tmp")
if [ "$TAILLE" -lt 10240 ]; then
  echo "ERREUR : sauvegarde suspecte ($TAILLE octets), conservée en .tmp pour analyse"
  exit 1
fi
mv "$FICHIER.tmp" "$FICHIER"
sha256sum "$FICHIER" > "$FICHIER.sha256"

if [ "$(date +%d)" = "01" ]; then
  cp "$FICHIER" "$FICHIER.sha256" "$DEST/mensuel/"
fi

find "$DEST/quotidien" -name 'sameva_*' -mtime +30 -delete
find "$DEST/mensuel"   -name 'sameva_*' -mtime +370 -delete

echo "[$(date -Iseconds)] Sauvegarde OK : $FICHIER ($TAILLE octets)"
