# 0005. Le serveur est l'unique autorité sur l'économie et la progression

- **Statut** : Proposé (implémenté dans le Sprint 1, en attente de validation)
- **Date** : 2026-10-21

---

## Contexte

Jusqu'à la v1.0.5, le client calculait et écrivait toute l'économie : la RLS
`player_stats_self_access` (FOR ALL) et `ai_validation_credits` (UPDATE)
permettaient à n'importe quel compte connecté d'écrire son or, son niveau ou ses
jetons IA. Le seuil de 70 de l'Oracle n'était appliqué qu'à l'affichage : le
bouton « Valider » restait actif quel que soit le score. Le gacha, le marché et
le craft tournaient en local (Hive). Or la promesse de Sameva est la
crédibilité : une récompense obtenue autrement que par l'effort réel la détruit.

## Décision

Le client lit et envoie des intentions ; le serveur seul écrit.

- Toute mutation de ressource passe par une fonction Postgres `SECURITY DEFINER`
  (`complete_quest`, `claim_daily`, `invoke`, `spend`...) ou par une Edge Function
  appelant des fonctions réservées au `service_role` (Oracle).
- Chaque mouvement est inscrit dans `economy_ledger`, registre en ajout seul :
  les soldes de `player_stats` en sont un cache, recalculable.
- Les règles d'équilibrage vivent dans `game_config` (lecture seule pour le
  client), modifiables sans republier l'app.
- Le client n'a plus que SELECT sur les données de jeu ; le statut et les
  récompenses d'une quête sont protégés par trigger.
- Chaque règle et chaque droit sont couverts par un test pgTAP.

## Alternatives écartées

- **Garder le calcul côté client et ajouter des contrôles de cohérence** : un
  client modifié contourne toujours un contrôle qu'il exécute lui-même.
- **Edge Functions pour toute la logique** : une récompense touche quête,
  registre, niveau et flamme ; hors de Postgres, l'atomicité demande des
  transactions distribuées ou des compensations.
- **Microservices** : sans objet pour un développeur seul ; l'atomicité du
  registre l'interdit à ce stade (voir le document d'architecture).

## Conséquences

- Positif : leaderboard, crédibilité et économie deviennent fiables ; chaque
  gain est auditable ; l'équilibrage se règle en base.
- Négatif : toute action de jeu exige le réseau (une file hors-ligne arrive au
  Sprint 2) ; la logique est en PL/pgSQL, moins familière que Dart.
- Dette assumée jusqu'au Sprint 3 : l'inventaire reste local ; deux
  passerelles transitoires plafonnées (`spend`, `claim_transitional_reward`)
  existent et seront supprimées.
- L'ancien APK devient incompatible : mise à jour forcée au déploiement.
