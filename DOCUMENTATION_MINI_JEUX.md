# Documentation - Mini-Jeux

## 🎮 Vue d'ensemble

Sameva inclut plusieurs mini-jeux pour permettre aux utilisateurs de se détendre tout en progressant dans l'application. Chaque mini-jeu offre une expérience unique et peut rapporter des récompenses.

---

## 📱 Page Principale des Mini-Jeux

**Fichier** : `lib/pages/minigame/minigame_page.dart`

### Description

Page listant tous les mini-jeux disponibles. Affiche chaque jeu dans une grille avec ses informations et permet de lancer le jeu.

### Éléments UI

#### En-tête
- **Titre** : "Mini-Jeux"
- **Sous-titre** : "Amusez-vous tout en progressant"
- **Badge** : "X/Y déverrouillés"

#### Grille de Mini-Jeux
- **Layout** : Grille 2 colonnes
- **Cartes** : Une carte par mini-jeu
- **Informations affichées** :
  - Icône du jeu
  - Nom du jeu
  - Description courte
  - Badge "Disponible" ou "Verrouillé"
  - Couleur d'accent

### Fonctionnalités

1. **Affichage**
   - Liste de tous les mini-jeux
   - Statut de déverrouillage
   - Navigation vers chaque jeu

2. **Déverrouillage**
   - Certains jeux peuvent être verrouillés
   - Déverrouillage via progression ou achat

3. **Navigation**
   - Tap sur une carte → Lancement du jeu
   - Message si verrouillé

---

## 🎯 Mini-Jeux Disponibles

### 1. Plateformer

**Fichier** : `lib/pages/minigame/games/platformer_game.dart`

#### Description

Jeu de plateforme classique avec 3 niveaux à compléter. Le joueur doit sauter de plateforme en plateforme pour atteindre la plateforme finale.

#### Gameplay

**Contrôles** :
- **Bouton Gauche** : Déplacer à gauche
- **Bouton Droite** : Déplacer à droite
- **Bouton Saut** : Sauter

**Mécaniques** :
- **Gravité** : Le joueur tombe automatiquement
- **Collisions** : Collision avec les plateformes
- **Collectibles** : Pièces jaunes à collecter (+10 points)
- **Niveaux** : 3 niveaux avec difficulté croissante

#### Niveaux

**Niveau 1** :
- 5 plateformes
- 4 collectibles
- Difficulté : Facile

**Niveau 2** :
- 6 plateformes
- 5 collectibles
- Difficulté : Moyen

**Niveau 3** :
- 8 plateformes
- 7 collectibles
- Difficulté : Difficile

#### Récompenses

- **Score** : Points basés sur les collectibles
- **Complétion** : XP bonus si tous les niveaux complétés
- **Temps** : Bonus si complété rapidement

#### Design

- **Fond** : Sombre (`#1a1a2e`)
- **Plateformes** : Violet (`AppColors.primary`)
- **Joueur** : Bleu
- **Collectibles** : Jaune
- **Contrôles** : Boutons circulaires en bas

---

### 2. Runner Endless

**Fichier** : `lib/pages/minigame/games/runner_game.dart`

#### Description

Jeu de course infinie où le joueur doit éviter les obstacles en sautant. La difficulté augmente progressivement.

#### Gameplay

**Contrôles** :
- **Bouton Saut** : Sauter pour éviter les obstacles

**Mécaniques** :
- **Course automatique** : Le joueur court automatiquement
- **Obstacles** : Blocs rouges à éviter
- **Gravité** : Le joueur retombe après le saut
- **Difficulté progressive** : Vitesse augmente avec la distance
- **Game Over** : Collision avec un obstacle

#### Scoring

- **Distance** : Points basés sur la distance parcourue
- **Score** : +10 points par obstacle évité
- **Meilleur score** : Sauvegardé localement

#### Design

- **Fond** : Sombre (`#1a1a2e`)
- **Sol** : Gris foncé (`#4a4a6a`)
- **Joueur** : Bleu
- **Obstacles** : Rouge
- **UI** : Score et distance en haut

---

### 3. Match-3

**Fichier** : `lib/pages/minigame/games/match3_game.dart`

#### Description

Jeu de puzzle classique où le joueur doit aligner 3 gemmes de la même couleur pour les faire disparaître.

#### Gameplay

**Contrôles** :
- **Tap** : Sélectionner une gemme
- **Tap sur autre gemme** : Échanger les positions

**Mécaniques** :
- **Grille** : 8x8 gemmes colorées
- **Match** : Aligner 3+ gemmes (horizontal ou vertical)
- **Chute** : Les gemmes tombent après suppression
- **Nouveaux** : Nouvelles gemmes générées en haut
- **Mouvements** : 30 mouvements par partie
- **Game Over** : Plus de mouvements disponibles

#### Scoring

- **Match simple** : +10 points par gemme
- **Combos** : Bonus pour matches multiples
- **Score final** : Total à la fin de la partie

#### Design

- **Grille** : 8x8 dans une carte
- **Gemmes** : 6 couleurs différentes
- **Sélection** : Bordure blanche épaisse
- **UI** : Score et mouvements en haut

---

### 4. Memory Quest

**Fichier** : `lib/pages/minigame/games/memory_quest_game.dart`

#### Description

Jeu de mémoire où le joueur doit reproduire une séquence de couleurs qui s'allongent à chaque niveau.

#### Gameplay

**Contrôles** :
- **Tap sur tuile** : Sélectionner une couleur

**Mécaniques** :
- **Séquence** : Séquence de couleurs affichée
- **Reproduction** : Le joueur doit reproduire la séquence
- **Niveaux** : La séquence s'allonge à chaque niveau
- **Erreur** : Game Over si mauvaise couleur
- **Progression** : Niveau augmente si séquence correcte

#### Scoring

- **Niveau** : Points basés sur le niveau atteint
- **Score** : Niveau × 10 points
- **Meilleur niveau** : Sauvegardé

#### Design

- **Grille** : 2x2 tuiles colorées
- **Couleurs** : Bleu, Vert, Orange, Violet
- **Animation** : Tuiles s'allument pendant la séquence
- **UI** : Niveau et score en haut

---

### 5. Speed Challenge

**Fichier** : `lib/pages/minigame/games/speed_challenge_game.dart`

#### Description

Jeu de rapidité où le joueur doit appuyer sur un bouton le plus rapidement possible dans un temps limité.

#### Gameplay

**Contrôles** :
- **Tap** : Appuyer sur le bouton

**Mécaniques** :
- **Temps limité** : 30 secondes
- **Bouton** : Apparition aléatoire
- **Score** : +1 point par tap réussi
- **Game Over** : Fin du temps

#### Scoring

- **Score** : Nombre de taps réussis
- **Précision** : Bonus si tous les taps réussis
- **Meilleur score** : Sauvegardé

#### Design

- **Bouton** : Grand bouton vert au centre
- **Timer** : Compte à rebours en haut
- **Score** : Affichage en temps réel
- **Feedback** : Animation à chaque tap

---

### 6. Puzzle Quest

**Fichier** : `lib/pages/minigame/games/puzzle_quest_game.dart`

#### Description

Jeu de puzzle de type "sliding puzzle" où le joueur doit réorganiser les tuiles pour former une image.

#### Gameplay

**Contrôles** :
- **Tap sur tuile** : Déplacer la tuile (si adjacente à l'espace vide)

**Mécaniques** :
- **Grille** : 3x3 tuiles (8 tuiles + 1 espace vide)
- **Objectif** : Réorganiser les tuiles dans l'ordre
- **Mouvements** : Nombre de mouvements comptés
- **Victoire** : Toutes les tuiles dans l'ordre

#### Scoring

- **Mouvements** : Moins de mouvements = meilleur score
- **Temps** : Bonus si complété rapidement
- **Score** : Calculé selon mouvements et temps

#### Design

- **Grille** : 3x3 dans une carte
- **Tuiles** : Numérotées ou avec images
- **Espace vide** : Tuile vide visible
- **UI** : Mouvements et temps en haut

---

## 🎁 Système de Récompenses

### Récompenses par Jeu

Chaque mini-jeu peut rapporter des récompenses :

1. **XP** : Expérience basée sur la performance
2. **Or** : Or basé sur le score
3. **Cristaux** : Cristaux pour excellente performance
4. **Items** : Items rares pour records

### Formules

**XP** :
```
XP = score / 10 (minimum 10 XP)
```

**Or** :
```
Or = score / 20 (minimum 5 or)
```

**Cristaux** :
```
Cristaux = 1 (si score > 1000)
```

---

## 🎨 Design Commun

### Principes

1. **Simplicité** : Contrôles simples et intuitifs
2. **Feedback** : Animations et effets visuels
3. **Progression** : Score et niveaux visibles
4. **Motivation** : Récompenses affichées

### Composants

- **AppBar** : Titre et bouton retour
- **Zone de jeu** : Zone principale du jeu
- **UI** : Score, niveau, temps
- **Contrôles** : Boutons de contrôle
- **Messages** : Game Over, Victoire, etc.

### Animations

- **Transitions** : Fade entre états
- **Effets** : Particules, glows
- **Feedback** : Animations de succès/échec

---

## 🔧 Intégration Technique

### Structure

Chaque mini-jeu est une page indépendante :
- `StatefulWidget` pour la gestion d'état
- `AnimationController` pour les animations
- Logique de jeu séparée

### Navigation

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const PlatformerGame(),
  ),
);
```

### Sauvegarde

- **Scores** : Sauvegardés localement (SharedPreferences)
- **Progression** : Sauvegardée par jeu
- **Records** : Meilleurs scores sauvegardés

---

## 📊 Statistiques

### Métriques Suivies

1. **Temps de jeu** : Temps total passé
2. **Parties jouées** : Nombre de parties
3. **Meilleur score** : Record personnel
4. **Récompenses gagnées** : Total XP/Or/Cristaux

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Erreur de chargement** : Message + retry
2. **Erreur de sauvegarde** : Message informatif
3. **Crash** : Gestion des exceptions

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Plus de mini-jeux
- [ ] Mode multijoueur
- [ ] Classements
- [ ] Défis quotidiens
- [ ] Récompenses spéciales
- [ ] Animations améliorées
- [ ] Effets sonores
- [ ] Thèmes personnalisables
- [ ] Difficultés ajustables
- [ ] Tutoriels intégrés

