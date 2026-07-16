# Dette technique Sameva

Registre des dettes techniques connues et assumées. Chaque entrée porte un statut (`[Ouvert]` ou `[Résolu]`),
une date de détection, une priorité et le composant concerné.

Ce registre couvre la dette **d'implémentation**. Les décisions d'architecture structurantes sont consignées
séparément dans [`adr/`](adr/README.md).

Dernière revue : 2026-07-16.

---

## [Ouvert] Résolution de conflit entre Hive et Supabase sur les stats joueur

**Détection** : 2026-05-15
**Priorité** : moyenne (non bloquant pour la publication, à traiter avant la première vague d'utilisateurs)
**Composant** : `lib/presentation/view_models/player_view_model.dart`

### Description

`loadPlayerStats` applique une stratégie « le serveur gagne » dès que `fetchRemoteStats` retourne des données.
Si l'utilisateur a progressé hors ligne, son instantané Hive est plus récent que celui de Supabase, mais la
branche « remote non nul » l'écrase sans comparaison. Les progrès réalisés hors ligne sont alors perdus.

Le cas d'erreur réseau est en revanche correctement traité : l'instantané Hive est conservé et Supabase n'est
pas écrasé, selon le principe « en cas de doute, ne jamais écraser la base ».

### Solution envisagée

Comparer les horodatages `updated_at` entre Hive et Supabase :

- `Hive.updated_at > Remote.updated_at` : utiliser Hive et pousser vers Supabase.
- `Remote.updated_at >= Hive.updated_at` : utiliser Supabase et écraser Hive.
- Modifications concurrentes sur deux appareils : privilégier la valeur la plus récente champ par champ.

### Effort estimé

Environ 30 minutes de code et 30 minutes de tests. Risque de régression faible si correctement testé.

---

## [Ouvert] Absence de repli sur le cache local pour les quêtes

**Détection** : 2026-05-15
**Priorité** : moyenne (contredit la stratégie offline-first annoncée)
**Composant** : `lib/presentation/view_models/quest_view_model.dart`, `lib/data/repositories/quest_repository.dart`

### Description

`QuestRepository` interroge exclusivement Supabase et n'utilise aucun cache local. Hors ligne, `loadQuests`
échoue, vide la liste en mémoire et affiche « Impossible de charger les quêtes. Vérifiez votre connexion. »,
alors que les autres domaines (stats, inventaire, équipement, compagnons, portefeuille) restent lisibles
depuis Hive.

Conséquence directe : une boîte Hive `quests` est ouverte dans `main.dart` mais n'est lue nulle part.

### Solution envisagée

- Tenter la lecture distante, puis retomber sur un cache Hive en cas d'erreur réseau, avec une bannière
  « Mode hors ligne » non bloquante.
- Resynchroniser automatiquement au retour du réseau.
- Arbitrer le conflit avec la source de vérité unique côté serveur, retenue pour garantir la cohérence
  des quêtes entre appareils.

### Effort estimé

Environ 45 minutes de code et de tests, hors stratégie de résolution de conflit.

---

## [Ouvert] Boîte Hive `quests` ouverte mais jamais utilisée

**Détection** : 2026-07-16 (audit de cohérence documentation et code)
**Priorité** : basse (code mort, aucun impact fonctionnel)
**Composant** : `lib/main.dart`

### Description

`await Hive.openBox('quests')` est exécuté au démarrage. Aucun repository ni ViewModel ne lit cette boîte.
Vestige d'une intention de cache local des quêtes jamais menée à terme.

### Solution envisagée

Supprimer l'ouverture de la boîte, ou l'exploiter dans le cadre de la dette précédente. Les deux entrées
doivent être traitées ensemble.

---

## [Ouvert] Dépendances de génération de code inutilisées

**Détection** : 2026-07-16 (audit de cohérence documentation et code)
**Priorité** : basse
**Composant** : `pubspec.yaml`

### Description

`hive_generator` et `build_runner` figurent dans les `dev_dependencies`, mais le projet ne contient aucune
annotation `@HiveType` ni `@HiveField`, et aucun fichier `.g.dart` n'est généré. La persistance Hive repose
sur du JSON simple (`toJson` / `fromJson`). Ces dépendances alourdissent la résolution sans contrepartie et
ont induit en erreur la documentation, qui mentionnait une étape `build_runner` inexistante.

### Solution envisagée

Retirer les deux dépendances, ou adopter réellement les `TypeAdapter` si un gain de performance de
sérialisation est recherché.

---

## [Ouvert] Tables déclarées mais non consommées

**Détection** : 2026-07-16 (audit de cohérence documentation et code)
**Priorité** : basse
**Composant** : `documentation/supabase_schema.sql`

### Description

Les tables `items`, `user_inventory` et `transactions` existent dans le schéma mais ne sont appelées par
aucune requête de l'application. L'inventaire et l'historique des transactions sont gérés localement dans
Hive. Le schéma décrit donc une cible non atteinte, ce qui peut laisser croire à une synchronisation qui
n'existe pas.

### Solution envisagée

Soit brancher la synchronisation de l'inventaire sur ces tables, soit les marquer explicitement comme cible
à venir dans la documentation. La seconde option est retenue à court terme.

---

## [Ouvert] Les avertissements d'analyse statique ne bloquent pas la chaîne

**Détection** : 2026-07-16 (audit de cohérence documentation et code)
**Priorité** : basse
**Composant** : `.github/workflows/ci.yml`

### Description

L'étape d'analyse statique s'exécute avec `flutter analyze --no-fatal-warnings`. Les avertissements sont
affichés mais ne font pas échouer le job : seule une erreur bloque. La porte de qualité est donc moins
stricte que ce que la règle projet « zéro issue » laisse entendre.

### Solution envisagée

Retirer le drapeau une fois vérifié que l'analyse ne remonte aucun avertissement, afin que la règle
« zéro issue » soit réellement appliquée par la chaîne.

---

## [Ouvert] Schéma initial non versionné

**Détection** : 2026-05-19
**Priorité** : moyenne (bloque la reconstruction d'un environnement vierge)
**Composant** : `supabase/migrations/`

### Description

Les tables fondatrices, dont `quests` et `companions`, proviennent d'un schéma appliqué manuellement et
absent du dossier de migrations. Sur une instance vierge, les migrations qui référencent ces tables
échouent, ce qui fait échouer l'étape de prévisualisation de la chaîne d'intégration sans affecter la
production.

### Solution envisagée

Créer une migration initiale versionnée rejouant les `CREATE TABLE` du schéma courant, afin de rendre la
reconstruction entièrement reproductible.
