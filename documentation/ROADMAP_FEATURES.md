# Roadmap des Fonctionnalités - Sameva

> Analyse complète du projet et recommandations de fonctionnalités à ajouter.
> Généré le 10/02/2026.

---

## Table des matières

1. [Résumé de l'existant](#1-résumé-de-lexistant)
2. [Priorité Haute — Compléter le coeur](#2-priorité-haute--compléter-le-coeur)
3. [Priorité Moyenne — Nouvelles fonctionnalités](#3-priorité-moyenne--nouvelles-fonctionnalités)
4. [Priorité Basse — Fonctionnalités avancées](#4-priorité-basse--fonctionnalités-avancées)
5. [Améliorations techniques](#5-améliorations-techniques)
6. [Monétisation & Engagement](#6-monétisation--engagement)

---

## 1. Résumé de l'existant

| Module | Avancement | Détails |
|--------|-----------|---------|
| Quêtes (CRUD, filtres, récompenses) | 95% | Complet et fonctionnel |
| Authentification | 100% | Login, register, onboarding, anonymous |
| Progression joueur (XP, level, HP, or) | 85% | Fonctionnel, services secondaires non activés |
| Inventaire (50 slots, stacking) | 80% | UI et logique en place |
| Équipement (6 slots) | 75% | Stockage OK, page avatar placeholder |
| Design System | 95% | 41 widgets, 3 catégories (minimalist/magical/fantasy) |
| Marché | 30% | Page placeholder uniquement |
| Gacha / Invocation | 30% | Page placeholder uniquement |
| Mini-jeux | 20% | 6 fichiers Flame squelettes |
| Social | 5% | Page vide |
| Notifications | 0% | Absent |
| Sync cloud complète | 40% | Quêtes sync, stats/inventaire en local uniquement |

**Avancement global : ~75%** — Le MVP est fonctionnel (quêtes + progression + inventaire).

---

## 2. Priorité Haute — Compléter le coeur

### 2.1 Finaliser les pages placeholder

**Page Marché (`MarketPage`)**
- Boutique avec items achetables (or / cristaux)
- Rotation quotidienne de 6 items (timer visible avec countdown)
- Onglets : Consommables, Équipement, Cosmétiques, Offres spéciales
- Promotions flash (items à prix réduit limités dans le temps)
- Confirmation d'achat avec aperçu de l'item

**Page Invocation / Gacha (`InvocationPage`)**
- Tirage simple (1 item) et tirage x10 (avec garantie rare+)
- Animation de vortex/portail pour le tirage (Rive ou Lottie)
- Système de pity : garantie Épique après 50 tirages, Légendaire après 100
- Invocation gratuite quotidienne (1 tirage/jour)
- Historique des tirages récents
- Coût en cristaux (monnaie premium)

**Page Avatar (`AvatarPage`)**
- Prévisualisation en temps réel de l'équipement sur l'avatar
- Drag & drop depuis l'inventaire vers les 6 slots
- Comparaison de stats (avant/après équipement)
- Visualisation de l'aura et du compagnon
- Onglets : Équipement, Apparence, Compagnon

**Page Profil (`ProfilePage`)**
- Statistiques complètes : quêtes terminées, taux de réussite, streak max
- Graphiques de progression (XP au fil du temps, quêtes par semaine)
- Historique des activités récentes
- Achievements/Succès débloqués
- Paramètres du compte (changement pseudo, email, thème)

### 2.2 Activer les services déjà créés

**`HealthRegenerationService`**
- Connecter au `PlayerProvider` avec un timer périodique
- Régénération passive : +1 HP / heure
- Régénération accélérée : potion = +20 HP instantanément
- Affichage du prochain point de régénération dans le HUD

**`BonusMalusService`**
- Appliquer les modificateurs actifs lors du calcul de récompenses dans `QuestProvider`
- Afficher les bonus/malus actifs sur le HUD (icônes avec tooltip)
- Sources de bonus : équipement, compagnon, consommables, streak
- Sources de malus : HP bas, moral bas, quêtes échouées

### 2.3 Consommables fonctionnels

- Bouton "Utiliser" sur les items consommables dans l'inventaire
- Effets des potions : soin HP, boost XP temporaire, boost or temporaire
- Effets de nourriture : régénération moral
- Durée des buffs temporaires (30 min, 1h, 24h)
- Indicateur visuel des buffs actifs sur le HUD

### 2.4 Validation avancée des quêtes

- **Validation photo** : prise de photo in-app, upload Supabase Storage, miniature sur la carte de quête
- **Validation timer** : chronomètre intégré (ex: méditer 10 min), notification à la fin
- **Validation géolocalisation** : rayon autour d'un lieu (ex: aller à la salle de sport)
- **Validation automatique** : quêtes récurrentes avec check-in simple

### 2.5 Récurrence automatique des quêtes

- Reset automatique des quêtes daily à minuit
- Reset des quêtes weekly le lundi
- Reset des quêtes monthly le 1er du mois
- Notification de rappel pour les quêtes récurrentes non complétées
- Historique de complétion par cycle

---

## 3. Priorité Moyenne — Nouvelles fonctionnalités

### 3.1 Système de notifications

- **Rappels de quêtes** : notification avant la deadline (1h, 30min)
- **Quêtes récurrentes** : rappel quotidien à heure configurable
- **Récompenses prêtes** : invocation gratuite disponible, marché renouvelé
- **Achievements** : notification toast in-app lors du déblocage
- **Streak en danger** : alerte si aucune quête complétée aujourd'hui (soir)
- Package suggéré : `flutter_local_notifications` + `awesome_notifications`

### 3.2 Système d'achievements / Succès

**Catégories :**
- **Quêtes** : Première quête, 10 quêtes, 100 quêtes, 1000 quêtes
- **Streak** : 7 jours, 30 jours, 100 jours, 365 jours consécutifs
- **Niveau** : Atteindre niveau 5, 10, 25, 50, 100
- **Collection** : Posséder un item de chaque rareté, collection complète d'un set
- **Exploration** : Jouer à chaque mini-jeu, débloquer chaque page
- **Social** : Ajouter un ami, terminer un défi coopératif
- **Secrets** : Easter eggs cachés dans l'app

**Récompenses par achievement :**
- XP bonus
- Or ou cristaux
- Items exclusifs (cadre d'avatar, titre, aura spéciale)

**UI :**
- Page dédiée avec grille de badges (grisés = non débloqués)
- Animation de déblocage (particules dorées + son)
- Barre de progression globale

### 3.3 Système de compagnons (Familier)

L'entité `Companion` existe déjà. Il faut l'exploiter :

- **Obtention** : via gacha spécial, quêtes spéciales, ou achievements
- **Progression** : le compagnon gagne de l'XP quand le joueur complète des quêtes
- **Niveaux** : 1 à 20, débloque des bonus passifs à chaque palier
- **Bonus passifs** : +5% XP, +5% or, régénération HP, etc.
- **Affichage** : compagnon visible à côté de l'avatar sur la SanctuaryPage
- **Nourrir** : utiliser des consommables pour augmenter le bonheur du compagnon
- **Évolutions** : à certains niveaux, le compagnon change d'apparence

### 3.4 Système de craft

- **Matériaux** : obtenus via quêtes, démontage d'items, mini-jeux
- **Recettes** : combinaisons de matériaux pour créer des items
- **Table de craft** : nouvelle section dans l'inventaire ou page dédiée
- **Niveaux de craft** : débloque des recettes de plus haute rareté avec la progression
- **Démontage** : détruire un item pour récupérer des matériaux (quantité selon rareté)

### 3.5 Mini-jeux fonctionnels

Les 6 fichiers Flame existent déjà. Pour chaque mini-jeu :

- **Match-3** : grille 8x8, combos, power-ups, 3 vies par partie
- **Memory Quest** : paires de cartes RPG, difficulté croissante, timer
- **Platformer** : niveaux avec pièces et ennemis, contrôles tactiles
- **Puzzle Quest** : casse-tête logique avec thème de quêtes
- **Runner infini** : obstacles, power-ups, distance = score
- **Speed Challenge** : réflexes rapides, QTE, score par temps

**Système commun à tous :**
- Coût d'entrée : énergie ou or
- Récompenses : or, XP, matériaux de craft, items rares
- High scores persistants (Hive)
- Classement global (Supabase)
- 3 niveaux de difficulté : facile (1x récompenses), normal (2x), difficile (3x)

### 3.6 Système de quêtes spéciales / Événements

- **Quêtes de boss hebdomadaires** : difficulté 5, récompenses épiques, collaboration possible
- **Événements saisonniers** : Noël, Halloween, été — quêtes thématiques limitées
- **Défis quotidiens** : 3 défis renouvelés chaque jour (ex: compléter 3 quêtes, gagner 500 or)
- **Quête principale** : fil narratif RPG avec chapitres à débloquer

### 3.7 Sync cloud complète

Actuellement, seules les quêtes sont synchronisées via Supabase. Il faut :

- **PlayerStats** : sync Hive ↔ Supabase (table `player_stats`)
- **Inventaire** : sync Hive ↔ Supabase (table `inventories`)
- **Équipement** : sync Hive ↔ Supabase (table `user_equipment` — déjà créée)
- **Stratégie** : écriture cloud à chaque modification, lecture locale (cache Hive)
- **Résolution de conflits** : timestamp le plus récent gagne
- **Backup automatique** : sync périodique toutes les 5 minutes
- **Multi-device** : pouvoir jouer sur téléphone ET tablette avec le même compte

---

## 4. Priorité Basse — Fonctionnalités avancées

### 4.1 Système social

**Amis :**
- Ajouter/supprimer des amis (par pseudo ou code)
- Voir le profil public d'un ami (niveau, achievements, avatar)
- Feed d'activité : "X a complété une quête légendaire"

**Classements :**
- Classement hebdomadaire : XP gagnée cette semaine
- Classement global : niveau total
- Classement par mini-jeu : high scores
- Filtres : amis uniquement / global

**Guildes / Clans :**
- Créer ou rejoindre un groupe (max 20 membres)
- Quêtes de guilde collectives (objectif commun)
- Chat interne de guilde
- Classement inter-guildes

**Défis entre amis :**
- Défier un ami sur une quête spécifique
- Le premier à compléter gagne un bonus
- Historique des duels

### 4.2 Système de classes / Spécialisations

- **4 classes** : Guerrier (+HP), Mage (+XP), Voleur (+Or), Paladin (+Streak bonus)
- Choix de classe à la création ou au niveau 5
- Compétences passives spécifiques à chaque classe
- Arbre de talents (3 branches par classe)
- Possibilité de changer de classe (coût en cristaux)

### 4.3 Donjon / Mode aventure

- **Système de donjons** : suite de défis (quêtes + mini-jeux)
- Étages progressifs avec difficulté croissante
- Boss de fin de donjon (quête spéciale difficile)
- Récompenses de donjon : sets d'équipement exclusifs
- Énergie limitée : 3 tentatives par jour
- Classement par étage atteint

### 4.4 Système d'enchantements

- **Améliorer les items** : utiliser des matériaux pour augmenter les stats
- **Niveaux d'enchantement** : +1 à +10
- **Risque d'échec** : à partir de +5, risque de casser l'item
- **Pierres de protection** : item consumable pour protéger contre la casse

### 4.5 Système de pets collectibles

Au-delà du compagnon principal :
- Collection de pets avec rareté
- Habitat/enclos à décorer
- Chaque pet donne un micro-bonus
- Breeding : combiner deux pets pour en obtenir un nouveau
- Albums de collection avec récompenses de complétion

### 4.6 Personnalisation poussée

- **Thèmes d'interface** : débloquer des thèmes visuels (nature, espace, steampunk)
- **Cadres d'avatar** : bordures décoratives obtenues via achievements
- **Titres** : texte sous le pseudo ("Tueur de procrastination", "Maître des quêtes")
- **Emotes / Stickers** : pour le chat social
- **Fond d'écran du sanctuaire** : personnaliser la page d'accueil

### 4.7 Mode hors-ligne amélioré

- File d'attente des actions en hors-ligne
- Sync automatique au retour de connexion
- Indicateur visuel du mode hors-ligne
- Quêtes jouables sans internet (sync au retour)

---

## 5. Améliorations techniques

### 5.1 Performance & Qualité

| Amélioration | Détails |
|-------------|---------|
| **Tests unitaires** | Couvrir les providers et services (objectif : 80% coverage) |
| **Tests de widgets** | Tester les composants clés (QuestCard, FloatingDock, HUD) |
| **Tests d'intégration** | Flux complets (créer quête → compléter → récompenses) |
| **CI/CD** | GitHub Actions : lint + test + build à chaque PR |
| **Crashlytics** | Firebase Crashlytics pour le suivi des erreurs en production |
| **Analytics** | Firebase Analytics : tracking des événements clés (quête créée, niveau up) |
| **Deep links** | Ouvrir l'app via un lien (ex: invitation d'ami, partage de quête) |
| **Internationalisation** | Support multilingue (FR par défaut, EN, ES) via `flutter_localizations` |

### 5.2 Sécurité

| Amélioration | Détails |
|-------------|---------|
| **RLS Supabase** | Vérifier que toutes les tables ont des policies Row Level Security |
| **Validation serveur** | Supabase Edge Functions pour valider les récompenses côté serveur |
| **Anti-triche** | Empêcher la modification des stats via Hive (checksum ou encryption) |
| **Rate limiting** | Limiter les appels API (invocations, achats) |

### 5.3 UX / Accessibilité

| Amélioration | Détails |
|-------------|---------|
| **Onboarding interactif** | Tutoriel pas-à-pas lors de la première utilisation (highlight des éléments) |
| **Haptic feedback** | Vibrations légères sur les actions importantes (level up, gacha, équipement) |
| **Animations de transition** | Transitions fluides entre toutes les pages (Hero animations) |
| **Mode sombre/clair** | Le `ThemeProvider` existe, activer le switch dans les paramètres |
| **Accessibilité** | Labels sémantiques, tailles de texte adaptables, contraste suffisant |
| **Skeleton loading** | Écrans de chargement avec shimmer au lieu de spinners |

---

## 6. Monétisation & Engagement

### 6.1 Rétention

| Mécanisme | Détails |
|-----------|---------|
| **Récompenses de connexion** | Calendrier de 30 jours avec récompenses croissantes |
| **Quêtes quotidiennes** | 3 défis rapides renouvelés chaque jour |
| **Streak rewards** | Récompenses à 7, 14, 30, 60, 90, 365 jours |
| **Roue de la fortune** | 1 spin gratuit/jour, spin supplémentaire = pub ou cristaux |
| **Énergie** | Système d'énergie pour les mini-jeux (se régénère avec le temps) |

### 6.2 Monétisation (optionnel)

| Mécanisme | Détails |
|-----------|---------|
| **Cristaux (IAP)** | Monnaie premium achetable (packs : 100, 500, 1200, 3000) |
| **Pass de saison** | Paliers gratuits et premium avec récompenses exclusives |
| **Publicités récompensées** | Regarder une pub = invocation gratuite, énergie, boost XP 30min |
| **Abonnement premium** | 2x XP permanent, invocation quotidienne, pas de pubs, thèmes exclusifs |
| **Packs starter** | Offre unique à -80% pour les nouveaux joueurs |

### 6.3 Viralité

| Mécanisme | Détails |
|-----------|---------|
| **Parrainage** | Code de parrainage : récompenses pour les deux joueurs |
| **Partage social** | Partager un achievement ou un item rare sur les réseaux |
| **Défis viraux** | Défis hebdomadaires partageables ("7 jours de méditation") |

---

## Ordre de développement recommandé

### Phase 1 — Compléter le MVP (2-3 semaines)
1. Finaliser MarketPage (achat/vente)
2. Finaliser InvocationPage (tirage gacha + animation)
3. Finaliser AvatarPage (équipement visuel)
4. Finaliser ProfilePage (stats + graphiques)
5. Activer HealthRegenerationService et BonusMalusService
6. Rendre les consommables fonctionnels

### Phase 2 — Engagement utilisateur (2-3 semaines)
7. Système de notifications (rappels, streak)
8. Achievements / Succès (UI + 30 premiers achievements)
9. Récurrence automatique des quêtes
10. Validation photo des quêtes
11. Récompenses de connexion quotidienne
12. Quêtes quotidiennes (3 défis/jour)

### Phase 3 — Contenu & Profondeur (3-4 semaines)
13. Système de compagnons fonctionnel
14. Système de craft (recettes + matériaux)
15. 2-3 mini-jeux jouables (Match-3, Memory, Runner)
16. Quêtes spéciales et événements
17. Sync cloud complète (PlayerStats, Inventory → Supabase)

### Phase 4 — Social & Polish (3-4 semaines)
18. Système d'amis et classements
19. Mode sombre/clair fonctionnel
20. Onboarding interactif amélioré
21. Tests (unitaires + widgets)
22. Restants mini-jeux (Platformer, Puzzle, Speed)

### Phase 5 — Avancé (optionnel)
23. Classes / Spécialisations
24. Donjon / Mode aventure
25. Guildes
26. Enchantements
27. Monétisation (IAP + ads)
28. Internationalisation
