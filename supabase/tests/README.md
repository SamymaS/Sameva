# Tests de la base Sameva (pgTAP)

Chaque règle du jeu et chaque droit d'accès est couvert par un test. Un test
qui échoue bloque la mise en production.

| Fichier | Ce qui est vérifié |
| --- | --- |
| `01_droits.test.sql` | Aucune écriture directe possible sur l'économie, isolation entre joueurs, fonctions réservées |
| `02_quetes.test.sql` | Garde-fous d'insertion et de modification, formule de récompense, rendements décroissants, flamme, niveaux |
| `03_oracle.test.sql` | Énergie, verdict, photo réutilisée, remboursement en cas de panne, abonné |
| `04_quotidien.test.sql` | `claim_daily` idempotent, quêtes manquées, état Épuisé, régénération |
| `05_gacha.test.sql` | Coûts en Sceaux, tirage gratuit, pity épique et légendaire |
| `06_transitoire_et_registre.test.sql` | Passerelles transitoires plafonnées, conservation du registre, immutabilité |
| `07_revue_securite.test.sql` | Non-régression des failles trouvées en revue (fuseau, champs figés, plafonds) |
| `08_defi_capture.test.sql` | Défi de capture : tirage, relance unique, vérification à l'aveugle, pannes |

## Lancer les tests

```bash
supabase start          # base locale avec toutes les migrations
supabase test db        # exécute supabase/tests/**/*.test.sql
```

Les aides communes (`tests.create_user`, `tests.login`, `tests.as_service`,
`tests.make_quest`…) sont dans `helpers/session.psql`, incluses par `\ir`.
Tout est fait dans une transaction annulée à la fin : la base reste propre.

## Edge Function Oracle

```bash
# Tests unitaires (Supabase et Anthropic simulés)
deno test --node-modules-dir=none --allow-net --allow-read \
  supabase/functions/analyze-quest-proof/index.test.ts supabase/functions/analyze-quest-proof/dhash.test.ts

# Test d'intégration contre la base locale (IA simulée)
SAMEVA_TEST_DB_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres \
  deno test --node-modules-dir=none --allow-env --allow-net --allow-read --allow-sys \
  supabase/functions/analyze-quest-proof/integration.test.ts
```
