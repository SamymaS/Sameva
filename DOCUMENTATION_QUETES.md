# Documentation - Système de Quêtes

## 🎯 Vue d'ensemble

Le système de quêtes est le cœur de Sameva. Il permet aux utilisateurs de transformer leurs tâches quotidiennes en quêtes de jeu de rôle, avec des récompenses, des niveaux de difficulté et un système de rareté.

---

## 📝 Types de Quêtes

### 1. Quêtes Quotidiennes
- **Fréquence** : Une fois par jour
- **Échéance** : 24 heures après création
- **Récompenses** : Modérées
- **Exemple** : "Faire 30 minutes de sport"

### 2. Quêtes Hebdomadaires
- **Fréquence** : Une fois par semaine
- **Échéance** : 7 jours après création
- **Récompenses** : Élevées
- **Exemple** : "Lire un livre complet"

### 3. Quêtes Mensuelles
- **Fréquence** : Une fois par mois
- **Échéance** : 30 jours après création
- **Récompenses** : Très élevées
- **Exemple** : "Apprendre une nouvelle compétence"

### 4. Quêtes Uniques
- **Fréquence** : Une seule fois
- **Échéance** : Définie par l'utilisateur
- **Récompenses** : Variables
- **Exemple** : "Organiser un événement"

---

## ⭐ Système de Rareté

Les quêtes ont différents niveaux de rareté qui affectent les récompenses :

1. **Commun** (Gris `#9E9E9E`)
   - Récompenses de base
   - Fréquence : 40%

2. **Peu Commun** (Vert `#4CAF50`)
   - Récompenses +20%
   - Fréquence : 25%

3. **Rare** (Bleu `#2196F3`)
   - Récompenses +50%
   - Fréquence : 20%

4. **Très Rare** (Violet `#9C27B0`)
   - Récompenses +100%
   - Fréquence : 10%

5. **Épique** (Orange `#FF9800`)
   - Récompenses +200%
   - Fréquence : 4%

6. **Légendaire** (Or `#FFD700`)
   - Récompenses +300%
   - Fréquence : 0.9%

7. **Mythique** (Rouge `#FF1744`)
   - Récompenses +500%
   - Fréquence : 0.1%

---

## 📊 Structure d'une Quête

### Modèle de Données

```dart
class Quest {
  String id;
  String userId;
  String title;
  String? description;
  QuestFrequency frequency; // daily, weekly, monthly, unique
  QuestRarity rarity;
  int difficulty; // 1-5
  Duration estimatedDuration;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? deadline;
  List<String> subQuests;
  QuestStatus status; // active, completed, archived, failed
}
```

### Propriétés

- **id** : Identifiant unique
- **userId** : Propriétaire de la quête
- **title** : Titre de la quête (obligatoire)
- **description** : Description détaillée (optionnel)
- **frequency** : Fréquence (daily, weekly, monthly, unique)
- **rarity** : Rareté (common à mythic)
- **difficulty** : Difficulté de 1 à 5
- **estimatedDuration** : Durée estimée
- **createdAt** : Date de création
- **completedAt** : Date de complétion (null si non complétée)
- **deadline** : Date limite (calculée automatiquement)
- **subQuests** : Liste des sous-quêtes
- **status** : Statut actuel

---

## 📱 Pages du Système de Quêtes

### 1. Page de Création de Quête

**Fichier** : `lib/pages/quest/fantasy_create_quest_page.dart`

#### Éléments UI

**Formulaire** :
- **Champ Titre** : Input texte (obligatoire)
- **Champ Description** : Textarea (optionnel)
- **Sélecteur Fréquence** : Dropdown (Quotidien, Hebdomadaire, Mensuel, Unique)
- **Sélecteur Difficulté** : Slider ou étoiles (1-5)
- **Sélecteur Durée** : Picker de durée (heures, minutes)
- **Sous-quêtes** : Liste dynamique
  - Bouton "Ajouter sous-quête"
  - Input pour chaque sous-quête
  - Bouton supprimer

**Boutons** :
- **"Créer la quête"** : Validation et création
- **"Annuler"** : Retour à la page précédente

#### Fonctionnalités

1. **Validation**
   - Titre non vide
   - Difficulté entre 1 et 5
   - Durée > 0

2. **Calcul automatique**
   - Rareté basée sur la difficulté et la fréquence
   - Deadline calculée selon la fréquence
   - ID unique généré

3. **Création**
   - Sauvegarde dans Firestore
   - Ajout à la liste des quêtes actives
   - Notification de succès

#### Design

- **Layout** : Formulaire scrollable
- **Style** : Fantasy avec `FantasyCard`
- **Couleurs** : Palette de l'application
- **Validation** : Messages d'erreur sous les champs

---

### 2. Page Liste des Quêtes

**Fichier** : `lib/pages/quest/quests_list_page.dart`

#### Éléments UI

**En-tête** :
- **Titre** : "Mes Quêtes"
- **Bouton "Créer"** : Navigation vers création
- **Statistiques** : Nombre total de quêtes

**Onglets** :
- **Actives** : Quêtes en cours
- **Terminées** : Quêtes complétées
- **Archivées** : Quêtes archivées

**Liste de Quêtes** :
- **Cartes de quêtes** : Une carte par quête
- **Informations affichées** :
  - Titre
  - Rareté (badge coloré)
  - Difficulté (étoiles ou nombre)
  - Progression (si sous-quêtes)
  - Temps restant
  - Statut
- **Actions** :
  - Bouton "Voir détails"
  - Bouton "Compléter" (si active)
  - Bouton "Archiver" (si terminée)

#### Fonctionnalités

1. **Filtrage**
   - Par statut (active, terminée, archivée)
   - Par rareté
   - Par difficulté
   - Par date

2. **Tri**
   - Par date de création
   - Par deadline
   - Par rareté
   - Par difficulté

3. **Recherche**
   - Recherche par titre
   - Recherche par description

4. **Actions**
   - Marquer comme complétée
   - Archiver une quête
   - Supprimer une quête
   - Dupliquer une quête

#### Design

- **Layout** : Liste verticale avec cartes
- **Cartes** : `FantasyCard` avec bordures colorées selon rareté
- **Badges** : Couleurs selon la rareté
- **Animations** : Transitions, hover effects

---

### 3. Page Détails de Quête

**Fichier** : `lib/pages/quest/quest_detail_page.dart`

#### Éléments UI

**En-tête** :
- **Titre** : Titre de la quête
- **Badge Rareté** : Badge coloré
- **Badge Fréquence** : Badge (Quotidien, etc.)

**Informations** :
- **Description** : Texte complet
- **Difficulté** : Affichage visuel (étoiles)
- **Durée estimée** : "X heures Y minutes"
- **Date de création** : Format lisible
- **Deadline** : Date limite avec compte à rebours
- **Statut** : Actif, Terminé, etc.

**Sous-quêtes** :
- **Liste** : Checkboxes pour chaque sous-quête
- **Progression** : "X/Y complétées"
- **Coche** : Marquer comme complétée

**Récompenses** :
- **XP** : Expérience gagnée
- **Or** : Or gagné
- **Cristaux** : Cristaux gagnés (si applicable)
- **Item** : Item de récompense (si applicable)
- **Bonus/Malus** : Affichage des modificateurs

**Actions** :
- **"Terminer la quête"** : Bouton principal
- **"Modifier"** : Édition (si active)
- **"Archiver"** : Archivage (si terminée)
- **"Supprimer"** : Suppression (avec confirmation)

#### Fonctionnalités

1. **Affichage**
   - Toutes les informations de la quête
   - Calcul des récompenses en temps réel
   - Affichage des bonus/malus

2. **Complétion**
   - Validation des sous-quêtes (optionnel)
   - Calcul des récompenses finales
   - Application des bonus/malus
   - Ajout de l'XP, or, cristaux
   - Ajout d'un item de récompense
   - Mise à jour du statut
   - Mise à jour du streak

3. **Modification**
   - Édition du titre, description
   - Modification de la difficulté
   - Ajout/suppression de sous-quêtes

#### Design

- **Layout** : Scroll vertical
- **Couleurs** : Badge de rareté en gradient
- **Animations** : Transitions, effets de complétion

---

## 🎁 Système de Récompenses

### Calcul des Récompenses de Base

**Formule** :
```
XP = 10 × difficulté
Or = 25 × difficulté
Cristaux = 1 (si difficulté > 3)
```

### Modificateurs

#### Bonus

1. **Complétion à temps** : +10%
2. **Complétion en avance** (20%+) : +25%
3. **Streak 3+ jours** : +10%
4. **Streak 7+ jours** : +20%
5. **Streak 14+ jours** : +30%
6. **Streak 30+ jours** : +40%
7. **100% quêtes du jour complétées** : +50%

#### Malus

1. **Retard** : -20%
2. **Quêtes manquées** (25%+) : -15%
3. **Quêtes manquées** (50%+) : -30%
4. **Inactivité 1 jour** : -10%
5. **Inactivité 3 jours** : -25%
6. **Inactivité 7 jours** : -40%

### Récompenses Finales

```dart
final baseXP = 10 * difficulty;
final baseGold = 25 * difficulty;

final multiplier = calculateMultiplier(bonuses, maluses);

final finalXP = (baseXP * multiplier).round();
final finalGold = (baseGold * multiplier).round();
```

### Items de Récompense

Chaque quête complétée donne un item selon sa rareté :
- **Commun** : Potion de base
- **Peu Commun** : Potion améliorée
- **Rare** : Arme rare
- **Très Rare** : Armure rare
- **Épique** : Arme épique
- **Légendaire** : Armure légendaire
- **Mythique** : Arme mythique

---

## 📊 Statistiques et Suivi

### Métriques Suivies

1. **Quêtes créées** : Nombre total
2. **Quêtes complétées** : Nombre et pourcentage
3. **Quêtes manquées** : Nombre et pourcentage
4. **Taux de complétion** : Pourcentage global
5. **Temps moyen** : Temps moyen pour compléter
6. **Rareté moyenne** : Rareté moyenne des quêtes
7. **Streak actuel** : Jours consécutifs
8. **Meilleur streak** : Record personnel

### Graphiques (Futur)

- Graphique de progression
- Répartition par rareté
- Évolution du taux de complétion
- Timeline des quêtes

---

## 🔄 États d'une Quête

### Statuts

1. **active** : Quête en cours, non complétée
2. **completed** : Quête terminée avec succès
3. **failed** : Quête échouée (deadline dépassée)
4. **archived** : Quête archivée par l'utilisateur

### Transitions

```
Créée → active
active → completed (si terminée à temps)
active → failed (si deadline dépassée)
completed → archived
failed → archived
```

---

## 🎨 Design et UX

### Principes

1. **Clarté** : Informations claires et lisibles
2. **Feedback** : Confirmation des actions
3. **Progression** : Affichage visuel de la progression
4. **Motivation** : Récompenses visibles

### Composants Utilisés

- `FantasyCard` : Cartes de quêtes
- `FantasyBadge` : Badges de rareté
- `FantasyButton` : Boutons d'action
- Progress bars : Barres de progression

### Animations

- **Création** : Animation d'apparition
- **Complétion** : Animation de succès
- **Transition** : Fade et slide

---

## 🔧 Intégration Technique

### Providers

**QuestProvider** (`lib/core/providers/quest_provider.dart`) :
- `createQuest()` : Création
- `completeQuest()` : Complétion
- `archiveQuest()` : Archivage
- `deleteQuest()` : Suppression
- `getQuests()` : Récupération
- `calculateRewards()` : Calcul des récompenses

### Firestore

**Collection** : `quests`

**Structure** :
```json
{
  "id": "quest_123",
  "userId": "user_456",
  "title": "Faire du sport",
  "description": "30 minutes de course",
  "frequency": "daily",
  "rarity": "rare",
  "difficulty": 3,
  "estimatedDuration": 1800,
  "createdAt": "2024-01-01T10:00:00Z",
  "completedAt": null,
  "deadline": "2024-01-02T10:00:00Z",
  "subQuests": ["Échauffement", "Course", "Étirements"],
  "status": "active"
}
```

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Titre vide** : "Le titre est obligatoire"
2. **Difficulté invalide** : "La difficulté doit être entre 1 et 5"
3. **Erreur de sauvegarde** : "Erreur lors de la création"
4. **Pas de connexion** : "Vérifiez votre connexion"

### États Vides

- **Aucune quête active** : Message + bouton créer
- **Aucune quête terminée** : Message approprié
- **Aucune quête archivée** : Message approprié

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Quêtes récurrentes automatiques
- [ ] Quêtes partagées entre utilisateurs
- [ ] Quêtes collaboratives
- [ ] Templates de quêtes
- [ ] Suggestions de quêtes basées sur l'historique
- [ ] Quêtes avec localisation (géolocalisation)
- [ ] Rappels et notifications
- [ ] Export des quêtes
- [ ] Statistiques avancées

