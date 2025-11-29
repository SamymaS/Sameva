# Mini-Jeux - Documentation

## 🎮 Mini-jeux disponibles

### 1. Memory Quest
**Fichier** : `lib/pages/minigame/games/memory_quest_game.dart`

**Description** : Jeu de mémoire classique où le joueur doit reproduire une séquence de couleurs qui s'allongent à chaque niveau.

**Règles** :
- Une séquence de couleurs s'affiche
- Le joueur doit reproduire la séquence en appuyant sur les tuiles dans le bon ordre
- La séquence s'allonge à chaque niveau
- Score : Niveau × 10 points par niveau complété

**Contrôles** : Appuyer sur les tuiles colorées pour reproduire la séquence

**Fonctionnalités** :
- Système de niveaux progressifs
- Score en temps réel
- Game Over avec possibilité de rejouer

---

### 2. Speed Challenge
**Fichier** : `lib/pages/minigame/games/speed_challenge_game.dart`

**Description** : Jeu de rapidité où le joueur doit appuyer sur le bouton vert le plus rapidement possible.

**Règles** :
- 4 boutons s'affichent, un seul est vert (les autres sont rouges)
- Le joueur doit appuyer sur le bouton vert
- +10 points pour une bonne réponse
- -5 points pour une mauvaise réponse
- 30 secondes pour marquer un maximum de points

**Contrôles** : Appuyer sur le bouton vert rapidement

**Fonctionnalités** :
- Timer de 30 secondes
- Score en temps réel
- Génération aléatoire de la position du bouton vert

---

### 3. Puzzle Quest
**Fichier** : `lib/pages/minigame/games/puzzle_quest_game.dart`

**Description** : Jeu de puzzle type taquin (15-puzzle) où le joueur doit réorganiser les tuiles numérotées.

**Règles** :
- Grille 3×3 avec 8 tuiles numérotées et une case vide
- Le joueur peut déplacer une tuile adjacente à la case vide
- Objectif : Réorganiser les tuiles dans l'ordre 1-8 avec la case vide en bas à droite
- Compteur de mouvements

**Contrôles** : Appuyer sur une tuile adjacente à la case vide pour la déplacer

**Fonctionnalités** :
- Mélange automatique du puzzle
- Compteur de mouvements
- Détection de la victoire
- Bouton pour mélanger à nouveau

---

## 🎯 Intégration

### Navigation
Les mini-jeux sont accessibles depuis la page `MiniGamePage` :
- Cliquer sur une carte de mini-jeu déverrouillée lance le jeu
- Chaque jeu s'ouvre dans une nouvelle page avec son propre AppBar

### Structure des fichiers
```
lib/pages/minigame/
├── minigame_page.dart          # Page principale avec la liste des jeux
└── games/
    ├── memory_quest_game.dart  # Jeu de mémoire
    ├── speed_challenge_game.dart # Jeu de rapidité
    └── puzzle_quest_game.dart   # Jeu de puzzle
```

## 🎨 Design

Tous les mini-jeux utilisent :
- Le thème de l'application (`AppColors`)
- Des cartes d'information pour afficher le score/niveau
- Des animations fluides
- Un design cohérent avec le reste de l'application

## 🔮 Améliorations futures possibles

1. **Système de récompenses** : Donner des XP ou de l'or après avoir joué
2. **Classements** : Sauvegarder les meilleurs scores
3. **Niveaux de difficulté** : Ajouter des options de difficulté
4. **Battle Arena** : Implémenter le 4ème mini-jeu
5. **Sons** : Ajouter des effets sonores pour chaque action
6. **Animations** : Améliorer les animations visuelles

## 📝 Notes techniques

- Tous les jeux sont créés avec Flutter pur (pas de Flame nécessaire pour ces jeux simples)
- Les jeux sont entièrement fonctionnels et jouables
- Le code est modulaire et facile à étendre
- Chaque jeu gère son propre état avec `StatefulWidget`





