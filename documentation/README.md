# Documentation Sameva

Index de la documentation technique du projet. Le point d'entrée général reste le [README racine](../README.md).

| Document | Contenu |
| -------- | ------- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | MVVM en quatre couches, règle de dépendance, inventaire des services et ViewModels, cycle de vie d'authentification |
| [SUPABASE_SETUP.md](SUPABASE_SETUP.md) | Création du projet, schéma, migrations, tables, RLS, clés et `.env` |
| [supabase_schema.sql](supabase_schema.sql) | Schéma SQL de base (sept tables fondatrices, enums, triggers, RLS) |
| [SUPABASE_EDGE_FUNCTION_IA.md](SUPABASE_EDGE_FUNCTION_IA.md) | Les cinq Edge Functions, secrets, déploiement, webhook Stripe |
| [IA_ANALYSE_IMAGE.md](IA_ANALYSE_IMAGE.md) | Validation de preuve par MougiBot (Claude Haiku Vision) : flux, format, robustesse, sécurité du prompt |
| [CI_CD.md](CI_CD.md) | Pipeline d'intégration continue réellement exécuté, et procédure de déploiement |
| [COUVERTURE_TESTS.md](COUVERTURE_TESTS.md) | Stratégie de test, répartition par couche, zones non couvertes |
| [../docs/adr/](../docs/adr/) | Enregistrements de décisions d'architecture (ADR) |

## Liens rapides

- **Démarrer** : [README racine](../README.md), section Démarrage rapide
- **Configurer le backend** : [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
- **Comprendre la validation IA** : [IA_ANALYSE_IMAGE.md](IA_ANALYSE_IMAGE.md)
