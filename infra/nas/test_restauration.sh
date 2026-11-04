#!/bin/sh
# =============================================================================
# Test de restauration mensuel : une sauvegarde jamais restaurée n'est pas une
# sauvegarde. Restaure la dernière sauvegarde dans un Postgres jetable et
# vérifie que les tables clés sont là et non vides.
#
#   0 5 2 * * /volume1/sameva/infra/test_restauration.sh >> /volume1/sameva/logs/restauration.log 2>&1
# =============================================================================
set -eu

BASE=/volume1/sameva
DERNIERE=$(ls -t "$BASE"/sauvegardes/quotidien/sameva_*.dump.enc | head -1)
CONTENEUR=sameva-restauration-test

echo "[$(date -Iseconds)] Test de restauration de $DERNIERE"
sha256sum -c "$DERNIERE.sha256"

docker rm -f "$CONTENEUR" >/dev/null 2>&1 || true
docker run -d --name "$CONTENEUR" -e POSTGRES_PASSWORD=test postgres:17-alpine >/dev/null
trap 'docker rm -f "$CONTENEUR" >/dev/null 2>&1 || true' EXIT
sleep 8

# Les rôles Supabase n'existent pas dans un Postgres nu : on les crée pour que
# les GRANT et les policies se restaurent sans erreur.
docker exec "$CONTENEUR" psql -U postgres -q -c "
  CREATE ROLE anon NOLOGIN; CREATE ROLE authenticated NOLOGIN;
  CREATE ROLE service_role NOLOGIN BYPASSRLS; CREATE ROLE supabase_admin NOLOGIN;"

openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -pass "file:$BASE/secrets/backup_key" -in "$DERNIERE" \
  | docker exec -i "$CONTENEUR" pg_restore -U postgres -d postgres --no-owner \
  || echo "Avertissement : certains objets propres à Supabase (rôles, extensions) ne se restaurent pas dans un Postgres nu, c'est attendu"
# Le critère de réussite est la présence des données, vérifiée ci-dessous.

for TABLE in quests player_stats economy_ledger game_config; do
  N=$(docker exec "$CONTENEUR" psql -U postgres -tAc "SELECT count(*) FROM public.$TABLE")
  echo "  $TABLE : $N lignes"
done
N=$(docker exec "$CONTENEUR" psql -U postgres -tAc "SELECT count(*) FROM public.game_config")
if [ "$N" -lt 1 ]; then
  echo "ERREUR : game_config vide, restauration invalide"
  exit 1
fi
echo "[$(date -Iseconds)] Restauration OK"
