# Banc d'essai Sameva

Un mini-Supabase complet, sans Docker, et l'app réelle pilotée comme un joueur.
Il sert à valider chaque modification de bout en bout avant qu'elle n'atteigne
un téléphone ou la production. Aucune donnée réelle, aucune clé de production.

| Composant | Rôle | Port |
| --- | --- | --- |
| PostgreSQL 16 | Base avec la baseline reconstruite et toutes les migrations | 54330 |
| GoTrue | Authentification (e-mail, invité) | 54332 |
| PostgREST | API REST et RPC | 54331 |
| Edge Functions (Deno) | `analyze-quest-proof` (Oracle **simulé**), `delete-account` | 54340+ |
| Passerelle | Une seule URL, comme Supabase : `/auth/v1`, `/rest/v1`, `/functions/v1` | **54321** |
| App web | Build Flutter web branché sur le banc | 8080 |

## Commandes

```bash
tools/banc/tout_tester.sh          # tout : analyse, tests Flutter, pgTAP, Oracle, API, parcours joueur
tools/banc/tout_tester.sh --sans-app
tools/banc/start.sh [--reset]      # démarre le banc (--reset : base vierge)
tools/banc/app.sh [--no-build]     # construit et sert l'app web
deno run -A tools/banc/fumee.ts    # test de fumée de l'API
cd tools/banc/e2e && node parcours.mjs [filtre]   # parcours joueur (Playwright)
cd tools/banc/e2e && node explore.mjs '<étapes JSON>'  # exploration libre avec captures
tools/banc/stop.sh
```

Captures d'écran : `/tmp/sameva-banc/captures/`. Journaux : `/tmp/sameva-banc/logs/`.

## Oracle simulé

`ORACLE_VISION=simulation` ne s'active que si `SUPABASE_URL` pointe sur la
machine locale (`simulation.ts`, testé) : impossible en production. Règle :
photo sombre → refusée (15), photo très claire → « ancienne photo » (90, défi
absent), sinon → preuve valable (85, défi observé). Photos de test générées
dans `/tmp/sameva-banc/photos` (`preuve.jpg`, `ancienne.jpg`, `sombre.jpg`).

## Réglages propres au banc

`reglages_banc.sql` : validation déclarative possible immédiatement, plafond de
création relevé. Rien d'autre ne diffère de la production.

## Limites

- Pas d'émulateur Android ici (pas de KVM) : caméra native, notifications,
  Play Integrity se testent sur le S918B ou sur l'émulateur du PC de dev.
- La baseline est reconstruite depuis le code : la vraie viendra du Sprint 0.
