# NAS Sameva (Terramaster F4-424 Pro)

Le NAS ne sert **jamais** la production : il héberge le staging, les
sauvegardes chiffrées de la production et la supervision. La production reste
sur Supabase managé (disponibilité, TLS, RGPD).

| Service | Rôle | Fichier |
| --- | --- | --- |
| Supabase auto-hébergé | Staging : recette des migrations et des Edge Functions | ci-dessous |
| Sauvegarde nocturne | `pg_dump` chiffré de la prod, 30 jours + 12 mois | `sauvegarde_supabase.sh` |
| Test de restauration | Restaure la dernière sauvegarde chaque mois et vérifie les données | `test_restauration.sh` |
| Uptime Kuma | Alerte si l'API, l'Oracle ou la sauvegarde tombe | `docker-compose.supervision.yml` |

## Arborescence sur le NAS

```
/volume1/sameva/
  infra/          ← ce dossier (copié depuis le dépôt)
  secrets/        ← chmod 700, fichiers chmod 600
    db_url        ← chaîne de connexion « Session pooler » (dashboard > Connect)
    backup_key    ← phrase de chiffrement, À COPIER AUSSI dans ton gestionnaire de mots de passe
  sauvegardes/quotidien/  sauvegardes/mensuel/
  logs/
  staging/        ← Supabase auto-hébergé
  uptime-kuma/
```

Sans `backup_key`, les sauvegardes sont illisibles : garde-la ailleurs que sur le NAS.

## 1. Sauvegardes

```sh
mkdir -p /volume1/sameva/secrets && chmod 700 /volume1/sameva/secrets
printf '%s' 'postgresql://postgres.mgddxrysvjlpfejbmfly:MOT_DE_PASSE@aws-0-eu-north-1.pooler.supabase.com:5432/postgres' > /volume1/sameva/secrets/db_url
openssl rand -base64 48 > /volume1/sameva/secrets/backup_key
chmod 600 /volume1/sameva/secrets/*
/volume1/sameva/infra/sauvegarde_supabase.sh      # premier essai à la main
/volume1/sameva/infra/test_restauration.sh        # doit finir par « Restauration OK »
```

Puis planifier les deux scripts (lignes `crontab` en tête de chaque fichier).
Vérifier l'hôte exact du pooler dans le dashboard (Connect > Session pooler).

## 2. Staging Supabase

Supabase fournit un déploiement Docker officiel. Sur le NAS (Docker / Portainer) :

```sh
cd /volume1/sameva/staging
git clone --depth 1 https://github.com/supabase/supabase
cp -r supabase/docker/* . && cp .env.example .env
# Éditer .env : POSTGRES_PASSWORD, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY,
# DASHBOARD_PASSWORD, SITE_URL (voir la doc « Self-Hosting with Docker »)
docker compose up -d
```

Depuis le PC de dev, appliquer les migrations et déployer les fonctions :

```powershell
supabase db push --db-url "postgresql://postgres:MOT_DE_PASSE@IP_DU_NAS:5432/postgres"
# Edge Functions : copier supabase/functions/* dans staging/volumes/functions/
# puis : docker compose restart functions
```

Le staging reste sur le réseau local. Pour tester depuis le S918B hors du Wi-Fi,
passer par un VPN (Tailscale), jamais par une ouverture de port.

Le secret `ANTHROPIC_API_KEY` du staging doit être une clé distincte de la
prod, avec un plafond de dépense bas.

## 3. Supervision

```sh
docker compose -f /volume1/sameva/infra/docker-compose.supervision.yml up -d
```

Créer les sondes décrites en tête du fichier, et une sonde « Push » appelée à
la fin de `sauvegarde_supabase.sh` : une sauvegarde qui ne tourne plus doit
déclencher une alerte, pas un silence.
