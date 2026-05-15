# Dette technique Sameva

Chaque entrée suit le format : `[Open]`/`[Done]`, date de détection, priorité, composant concerné.

---

## [Open] Stratégie de résolution conflit Hive vs Remote (offline-sync)

**Date détection** : 2026-05-15 (review du fix isolation utilisateur)
**Priorité** : Moyenne (pas bloquant publication MVP, mais à traiter avant 1ère vague d'utilisateurs)
**Composant** : lib/presentation/view_models/player_view_model.dart

### Description

Actuellement, `loadPlayerStats` applique une stratégie "Remote-wins" quand `fetchRemoteStats` retourne des données :
- Si l'utilisateur joue offline et a des stats Hive v2 (plus récentes)
- Si Supabase a des stats v1 (snapshot plus ancien)
- Au login avec connexion : la branche "remote != null" écrase v2 par v1
- Conséquence : progrès offline perdus

### Solution envisagée

Comparer les timestamps `updated_at` entre Hive et Remote :
- Si `Hive.updated_at > Remote.updated_at` → utiliser Hive ET push vers Supabase
- Si `Remote.updated_at >= Hive.updated_at` → utiliser Remote et écraser Hive
- Cas conflit (modifications concurrentes sur 2 appareils) → merge ou privilégier le plus récent par champ

### Effort estimé

- Petit refactor : ~30 min code + 30 min tests
- Risque régression faible si bien testé

### Lien

Détecté par @sameva-reviewer le 15/05/2026 dans le re-review du fix isolation utilisateur.

---

## [Open] Fallback Hive sur QuestViewModel.loadQuests

**Date détection** : 2026-05-15
**Priorité** : Basse (UX seulement, pas de corruption de données)
**Composant** : lib/presentation/view_models/quest_view_model.dart

### Description

Quand l'app est offline (mode avion, perte réseau), `loadQuests` affiche
"Impossible de charger les quêtes. Vérifiez votre connexion." même si
Hive contient un cache local de quêtes valides.

### Solution envisagée

- try `fetchRemoteQuests`
- catch network error → fallback sur `loadLocalQuests` + bannière "Mode hors ligne" non bloquante
- Resync automatique au retour réseau

### Effort estimé

~45 min code + tests
