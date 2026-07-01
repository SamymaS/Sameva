---
name: sameva-hive
description: Pattern de persistance locale Hive dans Sameva — boîtes dynamiques + sérialisation JSON (toJson/fromJson), clés par utilisateur, offline-first. À utiliser pour créer ou modifier un modèle persisté localement, ouvrir une boîte, lire/écrire dans Hive, ou implémenter un service/ViewModel source de vérité avec stockage local. Pour la sync cloud, voir sameva-supabase ; pour les tests, voir sameva-testing.
---

# Persistance Hive Sameva

## Principe fondamental

Sameva **n'utilise AUCUN TypeAdapter Hive**. Pas de `@HiveType`, pas de `@HiveField`,
pas de `.g.dart`, pas de `registerAdapter`, pas de `build_runner`.

Tous les modèles sont des **classes Dart immuables sérialisées en JSON** (`Map`)
et stockées dans des **boîtes dynamiques non typées** (`Box`). C'est le pattern réel
de `PlayerStats`, `CatStats`, `Item`, `AiValidationState`.

> ⚠️ Ne jamais introduire d'annotation `@HiveType` ni proposer `dart run build_runner build`
> pour Hive : ça ne correspond pas au codebase et ça casse la cohérence.

## Le modèle

Classe immuable avec `toJson()`, `fromJson(Map<String, dynamic>)`, `copyWith()`.
Pour les champs nullable dans `copyWith`, utiliser une sentinelle (distinguer
« null explicite » de « non fourni »).

```dart
class PlayerStats {
  final int gold;
  final DateTime? lastSync;

  const PlayerStats({this.gold = 0, this.lastSync});

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'lastSync': lastSync?.toIso8601String(),
      };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
        gold: json['gold'] as int? ?? 0,
        lastSync: json['lastSync'] != null
            ? DateTime.parse(json['lastSync'] as String)
            : null,
      );

  PlayerStats copyWith({int? gold, Object? lastSync = _sentinel}) => PlayerStats(
        gold: gold ?? this.gold,
        lastSync: lastSync == _sentinel ? this.lastSync : lastSync as DateTime?,
      );
}

const _sentinel = Object();
```

Règles : `DateTime` → `toIso8601String()` / `DateTime.parse(...)`. Toujours des
fallbacks défensifs au décodage (`as int? ?? 0`) pour tolérer un JSON ancien/partiel.

## Les boîtes

Toutes ouvertes au démarrage dans `lib/main.dart`, jamais ailleurs :

```dart
await Hive.openBox('quests');
final statsBox    = await Hive.openBox('playerStats');
final settingsBox = await Hive.openBox('settings');
await Hive.openBox('inventory');
await Hive.openBox('equipment');
await Hive.openBox('cats');
await Hive.openBox('aiValidation');
```

Ajouter un nouveau modèle persisté ⇒ ajouter `await Hive.openBox('maBoite');` ici.
Injecter ensuite la boîte dans le service/repository via `Hive.box('maBoite')`
(jamais de `openBox` en dehors de `main.dart`).

## Les clés

Deux variantes coexistent :

- **Clé fixe** — modèle mono-utilisateur sur l'appareil : `box.get('stats')`,
  `box.put('items', ...)`. Vu dans `PlayerRepository`, `InventoryViewModel`.
- **Clé par utilisateur** — à privilégier pour tout nouveau modèle multi-compte :
  `'nom_<userId>'`. Vu dans `CatViewModel` (`'cats_list_$uid'`) et
  `AiValidationCreditsService` (`'ai_validation_$uid'`).

Isoler la clé derrière un getter qui retourne `null` si l'utilisateur est inconnu →
toute mutation devient un **no-op propre** (aucun accès Hive sans userId) :

```dart
String? get _hiveKey {
  final uid = _currentUserId;
  if (uid == null || uid.isEmpty) return null;
  return 'ai_validation_$uid';
}
```

## Lecture / écriture

L'objet stocké revient de Hive en `Map` (ou `List`) **non typée** : toujours le
re-caster via `Map<String, dynamic>.from(...)` avant `fromJson`. C'est l'erreur
classique à ne pas oublier.

```dart
// Écriture
await box.put(key, model.toJson());

// Lecture d'un objet
final raw = box.get(key);
final model = raw != null
    ? Model.fromJson(Map<String, dynamic>.from(raw as Map))
    : Model.empty();

// Lecture d'une liste
final list = (box.get(key) as List<dynamic>? ?? [])
    .map((e) => Model.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();
```

Encadrer les accès d'un `try/catch` + `debugPrint` : un JSON corrompu ne doit
jamais crasher l'app, on retombe sur un état vide.

## Source de vérité + offline-first

Le service/ViewModel qui détient la boîte est la **source de vérité unique**
(cf. pattern source-de-vérité, sameva-architecture). Il :

1. persiste à **chaque** mutation (`box.put`) puis `notifyListeners()` ;
2. expose des getters en lecture seule, ne re-filtre jamais un snapshot externe ;
3. traite Hive comme l'autorité locale, Supabase en sync **best-effort** (fetch
   remote seulement si Hive est vide) :

```dart
if (_data.isEmpty && repo != null && uid != null) {
  final remote = await repo.fetchRemote(uid);
  if (remote.isNotEmpty) { _data = remote; await _persist(); }
}
```

4. vide l'état mémoire au logout **sans purger Hive** (les données restent isolées
   par userId pour le retour de l'utilisateur) :

```dart
void reset() {
  _userId = null;
  _state = Model.empty();
  notifyListeners();
}
```

Brancher `reset()` sur `onSignedOut` et le rechargement sur `onSignedIn` quand le
service écoute les changements d'auth.

## Piège FakeAsync + Hive dans les tests widget

`testWidgets` exécute son corps dans une **zone `FakeAsync`** : l'horloge (donc
les `Timer`) y est **virtuelle**, pilotée par `tester.pump(Duration)`. Mais une
écriture Hive (`box.put` / `box.delete` non triviale) déclenche une **vraie
écriture disque** dont le callback de complétion tourne sur la boucle
d'événements **réelle**, que `FakeAsync` ne fait jamais avancer.

⇒ Un `await box.put(...)` **deadlocke** dans la zone fake : le `Future` ne se
complète jamais et le test **timeout à 10 min** (symptôme piégeux : le test
« bloque » sans exception, souvent mis à tort sur le dos d'un `Timer`).

> Nuance : `box.delete` sur une clé **absente** est un no-op qui se résout
> synchronement → il « passe » parfois, ce qui masque le problème jusqu'à ce
> qu'une écriture réelle bloque. Ne pas s'y fier.

**Règle** : envelopper **toute écriture Hive** dans `tester.runAsync()` (zone
réelle). Les **lectures** (`box.get`) sont synchrones/en mémoire → OK partout,
y compris dans le `build`. `pumpWidget` / `pump` / `dispose` restent en zone fake.

```dart
testWidgets('...', (tester) async {
  // ✅ écriture Hive en zone réelle
  await tester.runAsync(() => Hive.box('settings').put('k', v));

  // ✅ build / pump / dispose en zone fake
  await tester.pumpWidget(_build());
  await tester.pump();
  // ... asserts ...
  await tester.pumpWidget(const SizedBox()); // dispose → annule les Timer
});
```

### Timer.periodic dans un widget testé

Un `Timer.periodic` (ex. compte à rebours qui se rafraîchit chaque seconde) **ne
bloque PAS `pump()`** en `FakeAsync` : il est simplement piloté par l'horloge
virtuelle. Il faut seulement :

- ❌ ne **jamais** appeler `pumpAndSettle()` (n'atteindrait jamais l'état stable
  avec un timer répétitif → timeout) ; utiliser `pump(const Duration(seconds: 1))`
  pour avancer l'horloge tic par tic ;
- ✅ **disposer** le widget en fin de test (`pumpWidget(const SizedBox())`) pour
  déclencher le `cancel()` du timer, sinon le framework lève « Timer still pending ».

> ⚠️ Ne PAS « contourner » en enveloppant `pumpWidget` dans `runAsync()` : ça crée
> un **vrai** `Timer` OS non piloté par la zone fake, qui reste pendant → même
> timeout 10 min. `runAsync` sert **uniquement** aux I/O réelles (écritures Hive),
> pas au cycle build/pump.

## Checklist — nouveau modèle persisté

1. Modèle immuable dans `data/models/` avec `toJson` / `fromJson` / `copyWith` / `empty()`.
2. `await Hive.openBox('maBoite');` dans `main.dart`.
3. Service/repository qui détient `Hive.box('maBoite')`, persiste à chaque mutation.
4. Clé par utilisateur `'nom_<userId>'` (getter null-safe → no-op).
5. Cast `Map<String, dynamic>.from(...)` à la lecture, `try/catch` défensif.
6. Tests avec boîte Hive temporaire (voir **sameva-testing**) — pas de `Hive.close()`
   en `tearDown` (bloque le runner ; cf. tests existants).

## Anti-patterns

- ❌ `@HiveType` / `@HiveField` / `TypeAdapter` / `registerAdapter` / `dart run build_runner build`.
- ❌ `Hive.openBox` ailleurs que dans `main.dart`.
- ❌ Lire un objet Hive sans `Map<String, dynamic>.from(...)` (cast `_InternalLinkedHashMap` qui plante).
- ❌ Purger Hive au logout (perte de données par utilisateur).
- ❌ Re-dériver / re-filtrer une copie locale au lieu de lire la source de vérité.
