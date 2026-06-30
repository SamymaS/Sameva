---
name: sameva-adr
description: Convention ADR Sameva. Déclenche sur : "ADR", "décision d'architecture", "choix technique justifié", "journal de décisions", "architecture decision record", "trade-off", "alternative écartée", "phase-zero", "restructuring".
---

# Convention ADR Sameva

Un **ADR** (Architecture Decision Record) capture une décision structurante :
*pourquoi* on a tranché ainsi, *quelles* options ont été écartées, et *ce que*
ça engage. Objectif : qu'une décision ne se re-discute pas trois fois, et qu'un
nouvel arrivant comprenne le « pourquoi » sans archéologie git.

## Règle d'or : l'ADR précède le code

Avant tout chantier structurel (nouvelle couche, changement de state management,
refonte navigation, choix de dépendance lourde, schéma de données, découpage de
modules), on **rédige l'ADR d'abord** et on **s'arrête pour validation humaine**.
Pas de code structurel tant que l'ADR n'est pas approuvé. Un ADR rejeté ou
remplacé n'est jamais supprimé : il passe en statut `Remplacé par NNNN`.

## Où ranger les ADR

Convention proposée : `docs/adr/NNNN-titre-en-kebab.md`
(ex. `docs/adr/0001-source-de-verite-unique-quetes.md`).

- Numérotation **séquentielle sur 4 chiffres**, jamais réutilisée.
- **Vérifier d'abord si un dossier d'ADR existe déjà** dans le repo (`docs/adr/`,
  `docs/decisions/`, `adr/`, `.adr/`…) avant d'en imposer un. S'il existe, suivre
  la convention en place. Sinon, créer `docs/adr/` (le dossier `docs/` existe
  déjà ; `docs/adr/` n'existe pas encore au moment de l'écriture de cette skill).
- Un fichier = une décision. Pas de fichier fourre-tout.

## Format ADR léger

```markdown
# NNNN — Titre court de la décision

- **Statut** : Proposé | Accepté | Remplacé par NNNN | Déprécié
- **Date** : AAAA-MM-JJ

## Contexte
Le problème, les contraintes, ce qui force une décision maintenant.
Factuel, pas de solution ici.

## Décision
Ce qu'on fait, à l'impératif. Une décision claire, pas un menu d'options.

## Alternatives écartées
- **Option A** — pourquoi écartée (coût, risque, dette, complexité…).
- **Option B** — pourquoi écartée.
(Une décision sans alternatives écartées est suspecte : on n'a pas cherché.)

## Conséquences
Ce que ça engage : positif ET négatif. Nouvelles contraintes, dette acceptée,
chantiers induits, ce qui devient plus dur.
```

## Bonnes pratiques

- **Court et actionnable** : un ADR tient sur une page. S'il déborde, la décision
  est probablement plusieurs décisions.
- **Immuable une fois Accepté** : on ne réécrit pas l'historique ; on crée un
  nouvel ADR qui remplace l'ancien et on met à jour le statut de l'ancien.
- **Nommer les trade-offs** : la valeur d'un ADR est dans « Alternatives écartées »
  et « Conséquences négatives », pas dans la justification de l'option retenue.
- **Lier au code** : référencer les fichiers/PR impactés quand le chantier démarre.
