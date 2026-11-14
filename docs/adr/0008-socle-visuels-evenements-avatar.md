# 0008. Socle pour la direction artistique : catalogue des visuels, événements de jeu, avatar du joueur

- **Statut** : Proposé (implémenté, en attente de validation par Samy)
- **Date** : 2026-11-14
- **Remplace** : [0002](0002-asset-resolver.md), [0003](0003-game-event-bus.md), [0004](0004-hero-avatar.md)

---

## Contexte

Sameva n'a pas de direction artistique définitive : le pixel art de novembre 2026
est provisoire, et la DA est confiée à une direction artistique externe (univers,
personnages, décors 2D et 3D, sons). Trois décisions de juillet 2026 préparaient
déjà l'arrivée d'assets définitifs, mais elles décrivaient un code qui n'existe
plus (icônes SVG, `AppNotification` comme seul retour, héros à classes, aucun son).

Entre-temps : les icônes sont des sprites pixel, les sons existent (`Sons`), le
serveur est autoritaire (ADR 0005), Riverpod est le socle des nouveautés (ADR 0007),
et la direction produit a changé : **l'avatar du joueur est au centre de
l'expérience**, MougiBot devient un robot, les classes de héros sont abandonnées.

Constat dans le code avant cette décision :

- chemins de fichiers écrits en dur dans les widgets (`chat_$race.png`,
  `mougibot.png`, `objets/$nom.png`, `sfx/$nom.wav`) ;
- 9 appels directs à `Sons.jouer` dans les écrans : changer ou ajouter un retour
  (son, vibration, animation) oblige à modifier chaque écran ;
- un personnage humain en couches (`CharacterPainter`, `CharacterAppearance`)
  écrit puis jamais affiché ; la fiche personnage montre l'initiale de l'e-mail.

## Décision

Trois briques, toutes côté client, sans effet sur les règles du jeu.

### 1. Catalogue des visuels et des sons (`lib/core/visuels/visuels.dart`)

Les écrans demandent un visuel par son **nom logique** (`Visuels.objet`,
`Visuels.chat`, `Visuels.mougibot`, `Visuels.avatar`, `Visuels.son`) et ne
connaissent plus aucun chemin. Le catalogue répond d'abord avec ce que la DA a
livré, décrit dans `assets/da/manifeste.json`, sinon avec le pixel art provisoire.

- Livrer un visuel = déposer un fichier dans `assets/da/` et ajouter une ligne au
  manifeste. Aucun écran n'est modifié ; ce qui n'est pas livré reste provisoire :
  la bascule peut se faire visuel par visuel.
- Chaque visuel dit s'il est en pixel art (agrandissement entier, sans lissage) ou
  non (lissé) : `style.pixel` dans le manifeste. `PixelSprite` gagne `lisse`.
- Un test vérifie que le manifeste du dépôt ne cite que des fichiers présents.

### 2. Événements de jeu (`lib/core/evenements/`)

Les écrans **annoncent** ce qui se passe (`BusJeu.emettre(TypeEvenement.x)`) ;
`Ambiance` s'abonne et traduit chaque événement en son et en vibration à l'aide
de deux tables. Les vibrations sont nouvelles, coupables dans les réglages
(`vibrations_actives`), absentes sur le web.

- Les 9 appels directs à `Sons.jouer` sont remplacés (seul l'aperçu du réglage
  « Effets sonores » reste direct).
- Sans abonné (tests d'un écran isolé), émettre ne fait rien.
- Les futures réactions (animations de l'avatar, de l'anti-personnage) s'abonneront
  au même flux, sans retoucher les écrans.

### 3. Avatar du joueur (`lib/ui/widgets/avatar/avatar_joueur.dart`)

`AvatarJoueur` affiche le personnage du joueur. Provisoirement, il est dessiné par
le code (`CharacterPainter`, enfin utilisé) à partir d'une apparence (silhouette,
teint, coiffure, couleur des cheveux) et d'une tenue en couches lue dans les
cosmétiques équipés. Si le manifeste fournit `avatar`, c'est le visuel de la DA
qui s'affiche.

- L'apparence est un état Riverpod (`apparenceAvatarProvider`), enregistré par
  compte dans la boîte Hive `settings`.
- La fiche personnage affiche l'avatar et permet de le personnaliser ; le profil
  montre son buste.
- Le Sanctuaire garde le chat tant que la DA n'a pas tranché la place de l'avatar,
  du compagnon et de la navigation (carte, village).

## Alternatives écartées

- **Appliquer 0002 à 0004 telles quelles** : elles ciblent des SVG, des héros à
  classes et `AppNotification`, tous abandonnés.
- **Attendre la DA pour câbler** : chaque livraison demanderait alors de modifier
  les écrans, et rien ne pourrait être testé d'ici là.
- **Télécharger les visuels depuis le serveur** : utile plus tard (événements
  saisonniers), prématuré tant que le style n'existe pas. Le manifeste garde la
  porte ouverte : seule la source du catalogue changerait.
- **Enregistrer l'apparence côté serveur dès maintenant** : elle ne touche aucune
  ressource de jeu (la règle n°1 ne s'applique pas) et rejoindra le serveur avec
  l'inventaire au Sprint 3, d'un seul geste.
- **Un bus typé par classes d'événements** : une énumération et une rareté
  facultative couvrent tous les cas actuels ; on enrichira au besoin.

## Conséquences

**Positif**

- Une livraison de la DA s'intègre sans toucher aux écrans, visuel par visuel.
- Sons et vibrations se règlent dans deux tables ; les écrans ne dépendent plus de
  `Sons`.
- L'avatar existe enfin à l'écran, personnalisable, et sert de point d'ancrage aux
  prochaines fonctionnalités (mini-jeux, social, anti-personnage).

**Négatif et dette acceptée**

- L'apparence n'est pas synchronisée entre appareils avant le Sprint 3.
- Les animations (manifeste `animations.json`) restent au format des feuilles de
  sprites pixel : un personnage 3D ou squeletté demandera un autre moteur de rendu
  (prototype Flutter Scene, à part).
- `AppNotification` et les animations locales aux pages ne passent pas encore par
  le bus : migration au fil de l'eau.

## Vérification

Tests unitaires (`test/core/visuels_test.dart`, `test/core/evenements_jeu_test.dart`),
tests de widget (`test/ui/avatar_joueur_test.dart`), scénario de bout en bout
« avatar : fiche personnage et apparence » (`tools/banc/e2e/parcours.mjs`).
