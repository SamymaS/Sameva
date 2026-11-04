# Décisions d'architecture (ADR)

Ce dossier consigne les décisions d'architecture structurantes du projet, au format
[Architecture Decision Record](https://adr.github.io/). Une décision par document, numérotée et datée.
Un ADR n'est jamais réécrit une fois accepté : il est remplacé par un ADR ultérieur qui le supersede.

| N° | Décision | Statut |
| --- | --- | --- |
| [0001](0001-cycle-de-vie-authentification.md) | Cycle de vie d'authentification uniforme des ViewModels et services | Accepté et implémenté |
| [0002](0002-asset-resolver.md) | AssetResolver : placeholders par défaut et contrat vers les assets définitifs | Proposé |
| [0003](0003-game-event-bus.md) | GameEventBus : découplage entre logique métier et animations | Proposé |
| [0004](0004-hero-avatar.md) | HeroAvatar : widget de héros en couches | Proposé |
| [0005](0005-serveur-autoritaire.md) | Le serveur est l'unique autorité sur l'économie et la progression | Proposé (implémenté au Sprint 1) |
| [0006](0006-defi-de-capture.md) | Défi de capture : prouver qu'une photo vient d'être prise | Proposé (implémenté au Sprint 1) |
| [0007](0007-socle-client-sprint2.md) | Socle client : go_router, Riverpod, Drift, configuration | Accepté (Sprint 2 en cours) |

## Statuts

| Statut | Signification |
| --- | --- |
| Proposé | La décision est documentée et argumentée, mais pas encore appliquée au code |
| Accepté et implémenté | La décision est appliquée et vérifiable dans le code |
| Superseded | Remplacée par un ADR ultérieur, conservée pour l'historique |

## Ordre de migration

```
0001 (cycle de vie auth)      prérequis : aucun ; implémenté en premier, risque runtime actif
  └─> 0002 (AssetResolver)    prérequis : 0001 terminé et projet vert
        └─> 0004 (HeroAvatar) prérequis : 0002
0003 (GameEventBus)           prérequis : 0001 ; parallélisable avec 0002
0005 (serveur autoritaire)    prérequis : baseline Supabase (Sprint 0)
  └─> 0006 (défi de capture)  prérequis : 0005
  └─> 0007 (socle client)     prérequis : 0005 déployé ; s'appuie sur 0003
```

Chaque phase se termine par `flutter analyze` à zéro et une suite de tests verte.
