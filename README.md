# Sameva

[![CI](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml/badge.svg)](https://github.com/SamymaS/Sameva/actions/workflows/ci.yml)
[![Backend](https://github.com/SamymaS/Sameva/actions/workflows/backend.yml/badge.svg)](https://github.com/SamymaS/Sameva/actions/workflows/backend.yml)

> **Fais de vraies choses, ta progression sera réelle.**

Sameva transforme les tâches du quotidien en quêtes de jeu vidéo : on gagne de l'expérience, de l'or et des objets, on monte de niveau et on fait évoluer son personnage. Sa différence : une quête peut exiger une **preuve**. Une photo prise sur le moment dans l'application est analysée par **MougiBot**, notre validateur IA, qui dit si la tâche a vraiment été faite.

Sameva est une application mobile (Android, iOS) en développement actif, **destinée à être commercialisée**.

---

## Où en est le projet

| Sujet | État |
| --- | --- |
| Application | Fonctionnelle sur Android et sur le web, en version de test |
| Publication sur les stores | Pas encore : prévue une fois la direction artistique définitive en place |
| Direction artistique | En cours de création ; le style pixel art actuel est **provisoire** |
| Backend | Serveur autoritaire en place : règles du jeu, récompenses et économie calculées côté serveur |
| Monétisation | Abonnement Premium (Stripe) intégré dans l'application |

---

## Ce qui rend Sameva différent

- **Une progression crédible.** Dans une to-do list, on coche une case et personne ne vérifie. Dans Sameva, la récompense se mérite : une quête prouvée rapporte plus qu'une quête déclarée sur l'honneur.
- **Une preuve difficile à truquer.** La photo est prise dans l'application (jamais depuis la galerie) et doit montrer un geste et un nombre manuscrit tirés au hasard par le serveur. MougiBot décrit l'image sans connaître le défi ; c'est le serveur qui compare.
- **Une économie honnête.** Toutes les récompenses sont calculées et enregistrées côté serveur. Les invocations se paient en Sceaux, une monnaie qui se gagne en jouant et ne s'achète jamais : aucun achat ne donne d'avantage.
- **Un ton bienveillant.** On encourage, on ne culpabilise pas : rater un jour est une pause, pas une faute.

---

## Fonctionnalités

**La boucle de base** : créer une quête, la faire, la prouver, être récompensé, progresser.

- **Quêtes** : création libre (catégorie, difficulté, répétition, échéance), quêtes toutes prêtes par thème, ou propositions générées par MougiBot.
- **Validation** : preuve photo analysée par l'IA avec défi de capture, minuteur, lieu, ou déclaration sur l'honneur (récompense réduite).
- **Progression** : niveaux, points de vie, moral, flamme (série de jours), succès, historique.
- **Portail** : invocation d'objets et de compagnons avec garanties (épique tous les 20 tirages, légendaire au 80e), boutique, revente.
- **Compagnons** : collection, personnalisation (chapeau, tenue, aura).
- **Mini-jeux** : anagramme, mémoire, nombres, réflexes, séquence.
- **Compte** : invité, e-mail ou Google ; un compte invité se convertit sans perdre sa progression ; suppression du compte conforme au RGPD.

---

## Feuille de route

L'avatar du joueur devient le centre de l'expérience :

- **Un avatar personnalisable** présent dans chaque écran et chaque action.
- **Un univers en 3D isométrique** : un village que le personnage parcourt (maison, tableau des quêtes, boutique, temple des invocations, observatoire de l'Oracle) à la place d'une navigation par onglets.
- **L'anti-personnage** : le double sombre et râleur de l'avatar, qui remplace les rappels classiques par des notifications pleines d'humour.
- **MougiBot en robot**, juge impartial des preuves.
- **Social bienveillant** : amis, encouragements, défis à plusieurs, sans classement humiliant.
- **Événements saisonniers**, plus de personnalisation, connexions avec des applications de sport, de langues ou de santé.
- **Publication** sur le Google Play Store et l'App Store.

---

## Modèle économique

Freemium, sans avantage payant :

- **Gratuit** : toutes les fonctionnalités, avec un nombre limité de vérifications photo par MougiBot (l'énergie de l'Oracle).
- **Premium** (abonnement) : vérifications illimitées.
- **Jamais** d'achat de monnaie de jeu ni d'objet qui rende plus fort.

---

## Stack technique

| Couche | Technologie |
| --- | --- |
| Application | Flutter (Android, iOS, web), navigation go_router, état Riverpod (Provider pour l'existant, en cours de migration) |
| Backend | Supabase : PostgreSQL (fonctions RPC autoritaires, RLS, journal `economy_ledger` en ajout seul), Auth, Edge Functions Deno |
| IA | Anthropic Claude (vision), appelé uniquement depuis les Edge Functions |
| Paiement | Stripe (abonnement) |
| Cache local | Hive (JSON, sans génération de code) |
| Qualité | Tests Flutter, tests pgTAP de la base, tests Deno de l'Oracle, banc d'essai de bout en bout (Playwright) |
| CI/CD | GitHub Actions |
| Infra | Supabase managé en production ; NAS pour la préproduction, les sauvegardes chiffrées et la supervision |

**Règle d'or : le serveur est l'unique autorité.** Le client lit l'état et envoie des intentions ; il n'écrit jamais l'XP, l'or, les Sceaux ou le résultat d'une invocation. Les clés d'API (Anthropic, Stripe) ne quittent jamais le serveur. Les choix structurants sont consignés dans des [enregistrements de décision d'architecture](docs/adr/).

---

## Pour les développeurs

### Démarrage

```bash
git clone https://github.com/SamymaS/Sameva.git
cd Sameva
cp config/exemple.json config/dev.json   # renseigner l'URL et la clé publique Supabase (voir config/README.md)
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

Prérequis : Flutter (canal stable) et un projet Supabase avec les migrations de `supabase/migrations/`.

### Tests

```bash
tools/banc/tout_tester.sh   # tout : analyse, tests Flutter, pgTAP, Oracle, API, parcours joueur sur l'app web
flutter analyze
flutter test
supabase test db            # règles du jeu et droits (pgTAP)
```

Le banc d'essai lance un mini-Supabase local et pilote l'application comme un joueur : voir [tools/banc/README.md](tools/banc/README.md).

### CI/CD

| Workflow | Rôle |
| --- | --- |
| `ci.yml` | Analyse statique et tests Flutter à chaque push et pull request |
| `backend.yml` | Tests pgTAP de la base et tests de l'Edge Function Oracle |
| `deploy.yml` | Déploiement manuel des Edge Functions, **après** `supabase db push` |
| `release.yml` | Compilation de l'APK et publication d'une Release, sur étiquette `v*` |

### Documentation

| Document | Contenu |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Vue d'ensemble technique à jour : architecture, règles, design system |
| [docs/adr/](docs/adr/) | Décisions d'architecture (serveur autoritaire, défi de capture, socle client…) |
| [docs/runbooks/](docs/runbooks/) | Procédures de déploiement et de test sur Android |
| [docs/qa/constats.md](docs/qa/constats.md) | Constats d'usage (bugs, UX, accessibilité) |
| [infra/nas/](infra/nas/) | Préproduction, sauvegardes et supervision |
| [documentation/](documentation/) | Documentation historique (architecture initiale, Supabase, IA) |

---

## Licence

Logiciel propriétaire. © 2025-2026 Samy BOUDAOUD. Tous droits réservés.

Le code de ce dépôt est consultable, mais aucune licence n'est accordée : toute reproduction, modification, distribution ou utilisation commerciale, totale ou partielle, est interdite sans autorisation écrite.
