# Documentation - Fonctionnalités Système

## 🎮 Vue d'ensemble

Sameva inclut plusieurs systèmes de gameplay interconnectés qui créent une expérience de gamification complète pour la gestion de tâches.

---

## 📊 Système d'Expérience et de Niveaux

### Formule de Niveau

**Fichier** : `lib/core/providers/player_provider.dart`

#### Calcul de l'XP Requis

```
XP requis pour niveau N = 100 × (N × 1.5)
```

**Exemples** :
- Niveau 1 → 2 : 150 XP
- Niveau 2 → 3 : 300 XP
- Niveau 3 → 4 : 450 XP
- Niveau 10 → 11 : 1500 XP

#### Gain d'XP

- **Quêtes complétées** : XP selon difficulté et bonus/malus
- **Mini-jeux** : XP basé sur le score
- **Items** : Potions d'expérience, parchemins, tomes

#### Montée de Niveau

- **Animation** : `LevelUpAnimation`
- **Récompenses** :
  - +10 PV max
  - Notification de succès
  - Célébration visuelle

---

## ❤️ Système de Points de Vie (PV)

### PV de Base

- **Niveau 1** : 100 PV
- **Par niveau** : +10 PV max
- **Formule** : `PV max = 100 + (niveau - 1) × 10`

### Régénération Automatique

**Fichier** : `lib/services/health_regeneration_service.dart`

#### Taux de Base

- **Base** : 1% des PV max par heure
- **Calcul** : `Régénération = PV max × 0.01 × heures`

#### Modificateurs

**Bonus** :
- **Quêtes complétées** : +50% si taux de complétion > 80%
- **Streak 7+ jours** : +20%
- **Moral élevé (> 0.7)** : +30%

**Malus** :
- **Moral bas (< 0.5)** : -50%
- **Inactivité** : -25% par jour d'inactivité

#### Régénération après Quête

- **Complétée à temps** : +10% PV max
- **Complétée en avance** : +15% PV max
- **Complétée en retard** : +5% PV max

### Perte de PV

#### Causes

1. **Quêtes manquées** :
   - -2% PV max par quête manquée
   - Maximum : -20% PV max

2. **Moral très bas (< 0.2)** :
   - -5% PV max progressivement
   - Perte continue jusqu'à amélioration

3. **Inactivité prolongée** :
   - -1% PV max par jour d'inactivité (après 3 jours)

### Mort du Personnage

#### Conditions

- **PV = 0** : Le personnage meurt

#### Conséquences

1. **Réinitialisation** :
   - Niveau → 1
   - XP → 0
   - Or → 50% de l'or actuel
   - PV → 100 (max)

2. **Pénalité de crédibilité** :
   - -0.2 crédibilité (minimum 0.0)

3. **Notification** :
   - Message de mort
   - Explication des conséquences

#### Prévention

- Compléter les quêtes à temps
- Maintenir un moral élevé
- Utiliser des potions de soin
- Éviter l'inactivité prolongée

---

## 🎁 Système de Bonus/Malus

**Fichier** : `lib/services/bonus_malus_service.dart`

### Calcul des Bonus

#### Complétion Quotidienne

- **100% complétées** : +50% récompenses
- **80%+ complétées** : +30% récompenses
- **50%+ complétées** : +10% récompenses

#### Streak (Jours Consécutifs)

- **30+ jours** : +40% récompenses
- **14+ jours** : +30% récompenses
- **7+ jours** : +20% récompenses
- **3+ jours** : +10% récompenses

#### Ponctualité

- **Terminée en avance (20%+)** : +25% récompenses
- **Terminée à temps** : +10% récompenses

### Calcul des Malus

#### Quêtes Manquées

- **50%+ manquées** : -30% récompenses
- **25%+ manquées** : -15% récompenses

#### Inactivité

- **7+ jours** : -40% récompenses
- **3+ jours** : -25% récompenses
- **1 jour** : -10% récompenses

#### Retard

- **Terminée après l'échéance** : -20% récompenses

### Application

```dart
final baseXP = 10 * difficulty;
final baseGold = 25 * difficulty;

final multiplier = calculateMultiplier(bonuses, maluses);

final finalXP = (baseXP * multiplier).round();
final finalGold = (baseGold * multiplier).round();
```

---

## 💰 Système Économique

### Monnaies

#### Or

- **Utilisation** : Achat d'items au marché, invocations
- **Gain** :
  - Quêtes complétées
  - Mini-jeux
  - Items (pièces, potions d'or)
- **Stockage** : `PlayerProvider.stats.gold`

#### Cristaux

- **Utilisation** : Invocations premium
- **Gain** :
  - Quêtes difficiles (difficulté > 3)
  - Mini-jeux (scores élevés)
  - Achats in-app (futur)
- **Stockage** : `PlayerProvider.stats.crystals`

### Calcul des Prix

#### Marché

- **Base** : Défini dans `ItemFactory`
- **Modificateurs** : Aucun (prix fixes)

#### Invocations

- **Gratuite** : 0 (1 par jour)
- **Standard** : 100 or
- **Premium** : 10 cristaux

---

## 📈 Statistiques du Joueur

### Modèle de Données

**Fichier** : `lib/core/providers/player_provider.dart`

```dart
class PlayerStats {
  int level;
  int experience;
  int experienceToNextLevel;
  int gold;
  int crystals;
  int currentHealth;
  int maxHealth;
  double moral; // 0.0 à 1.0
  int streak; // Jours consécutifs
  double credibility; // 0.0 à 1.0
  DateTime? lastActiveDate;
  DateTime createdAt;
}
```

### Propriétés

- **level** : Niveau actuel (commence à 1)
- **experience** : XP actuelle
- **experienceToNextLevel** : XP nécessaire pour le prochain niveau
- **gold** : Or disponible
- **crystals** : Cristaux disponibles
- **currentHealth** : PV actuels
- **maxHealth** : PV maximum
- **moral** : Moral (0.0 = très bas, 1.0 = excellent)
- **streak** : Jours consécutifs actifs
- **credibility** : Crédibilité (0.0 = faible, 1.0 = excellente)
- **lastActiveDate** : Dernière date d'activité
- **createdAt** : Date de création du compte

### Calculs Automatiques

#### Moral

- **Base** : 1.0
- **Quêtes complétées** : +0.05 par quête
- **Quêtes manquées** : -0.1 par quête
- **Streak** : +0.02 par jour de streak
- **Inactivité** : -0.05 par jour

#### Crédibilité

- **Base** : 1.0
- **Quêtes complétées à temps** : +0.01
- **Quêtes complétées en avance** : +0.02
- **Quêtes manquées** : -0.05
- **Mort** : -0.2

---

## 🎯 Système de Streak

### Calcul

- **Incrément** : +1 par jour d'activité
- **Reset** : Si pas d'activité pendant 1 jour
- **Maximum** : Illimité

### Bonus de Streak

- **3+ jours** : +10% récompenses
- **7+ jours** : +20% récompenses
- **14+ jours** : +30% récompenses
- **30+ jours** : +40% récompenses

### Mise à Jour

**Fichier** : `lib/core/providers/player_provider.dart`

```dart
Future<void> updateStreak(String userId) async {
  final stats = await getStats(userId);
  final now = DateTime.now();
  final lastActive = stats?.lastActiveDate;
  
  if (lastActive == null) {
    // Premier jour
    await _setStreak(userId, 1);
  } else {
    final daysSince = now.difference(lastActive).inDays;
    
    if (daysSince == 0) {
      // Même jour, pas de changement
      return;
    } else if (daysSince == 1) {
      // Jour consécutif
      await _setStreak(userId, (stats?.streak ?? 0) + 1);
    } else {
      // Streak cassé
      await _setStreak(userId, 1);
    }
  }
  
  await _setLastActiveDate(userId, now);
}
```

---

## 🏆 Système de Récompenses

### Récompenses de Quêtes

#### Calcul de Base

```dart
XP = 10 × difficulté
Or = 25 × difficulté
Cristaux = 1 (si difficulté > 3)
```

#### Application des Modificateurs

```dart
final multiplier = calculateMultiplier(bonuses, maluses);

final finalXP = (baseXP * multiplier).round();
final finalGold = (baseGold * multiplier).round();
```

#### Items de Récompense

Chaque quête complétée donne un item selon sa rareté :
- **Commun** : Potion de base
- **Peu Commun** : Potion améliorée
- **Rare** : Arme rare
- **Très Rare** : Armure rare
- **Épique** : Arme épique
- **Légendaire** : Armure légendaire
- **Mythique** : Arme mythique

### Récompenses de Mini-Jeux

#### Formules

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

## 🔄 Synchronisation

### Stockage Local

- **Hive** : Données locales
  - Inventaire
  - Équipement
  - Statistiques du joueur

### Synchronisation Cloud

- **Firestore** : Données cloud
  - Quêtes
  - Statistiques du joueur
  - Progression

### Mise à Jour

- **Temps réel** : Écoute des changements Firestore
- **Manuelle** : Pull-to-refresh (optionnel)
- **Automatique** : Synchronisation périodique

---

## 📊 Métriques et Analytics

### Métriques Suivies

1. **Progression** :
   - Niveau actuel
   - XP totale gagnée
   - Temps de jeu

2. **Quêtes** :
   - Nombre créées
   - Nombre complétées
   - Taux de complétion
   - Temps moyen

3. **Économie** :
   - Or gagné/dépensé
   - Cristaux gagnés/dépensés
   - Items obtenus

4. **Engagement** :
   - Streak actuel
   - Jours actifs
   - Fréquence de connexion

---

## 🐛 Gestion des Erreurs

### Erreurs Communes

1. **Données corrompues** : Réinitialisation des données
2. **Synchronisation échouée** : Retry automatique
3. **Calcul invalide** : Valeurs par défaut

### Récupération

- **Backup automatique** : Sauvegarde locale
- **Validation** : Vérification des données
- **Fallback** : Valeurs par défaut si erreur

---

## 📝 Notes de Développement

### Améliorations Futures

- [ ] Système de guildes
- [ ] Quêtes collaboratives
- [ ] Événements spéciaux
- [ ] Achievements/Badges
- [ ] Classements
- [ ] Défis hebdomadaires
- [ ] Récompenses saisonnières
- [ ] Système de parrainage

