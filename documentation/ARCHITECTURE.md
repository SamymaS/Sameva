# Architecture du Projet Sameva

## 📁 Structure du Projet

Le projet a été réorganisé selon une architecture professionnelle séparant clairement le **backend** (logique métier et données) du **frontend** (interface utilisateur).

### Structure des dossiers

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── app_new.dart                 # Configuration de l'application Flutter
│
├── config/                      # Configuration
│   └── supabase_config.dart     # Configuration Supabase
│
├── data/                        # BACKEND - Couche de données
│   ├── datasources/            # Sources de données
│   │   ├── local/              # Stockage local (Hive)
│   │   └── remote/             # API distante (Supabase)
│   ├── repositories/            # Repositories (abstraction)
│   └── models/                 # Modèles de données (DTO)
│
├── domain/                      # BACKEND - Logique métier
│   ├── entities/                # Entités du domaine
│   │   ├── quest.dart           # Entité Quest
│   │   ├── item.dart            # Entité Item
│   │   └── equipment.dart       # Entité Equipment
│   ├── repositories/            # Interfaces des repositories
│   └── services/                # Services métier
│       ├── quest_rewards_calculator.dart
│       ├── bonus_malus_service.dart
│       ├── health_regeneration_service.dart
│       └── item_factory.dart
│
├── presentation/                # FRONTEND - Couche de présentation
│   └── providers/               # State management (Provider)
│       ├── auth_provider.dart
│       ├── quest_provider.dart
│       ├── player_provider.dart
│       ├── inventory_provider.dart
│       ├── equipment_provider.dart
│       └── theme_provider.dart
│
└── ui/                          # FRONTEND - Interface utilisateur
    ├── pages/                   # Pages de l'application
    │   ├── auth/               # Authentification
    │   ├── home/               # Page d'accueil
    │   ├── quest/               # Gestion des quêtes
    │   ├── profile/             # Profil utilisateur
    │   ├── inventory/           # Inventaire
    │   ├── market/              # Marché
    │   ├── minigame/            # Mini-jeux
    │   └── ...
    ├── widgets/                 # Widgets réutilisables
    │   ├── common/              # Widgets communs
    │   ├── animations/          # Animations
    │   ├── fantasy/             # Widgets fantasy
    │   ├── figma/               # Widgets Figma
    │   └── ...
    └── theme/                   # Thème et styles
        ├── app_theme.dart
        ├── app_colors.dart
        └── app_styles.dart
```

## 🔄 Flux de données

```
UI (Pages/Widgets)
    ↓
Presentation (Providers)
    ↓
Domain (Services/Entities)
    ↓
Data (Repositories)
    ↓
DataSources (Supabase/Hive)
```

## 📝 Principes d'architecture

1. **Séparation des responsabilités** : Chaque couche a un rôle précis
2. **Dépendances unidirectionnelles** : UI → Presentation → Domain → Data
3. **Abstraction** : Les repositories sont des interfaces dans domain
4. **Réutilisabilité** : Les services métier sont indépendants de l'UI

## 🎯 Couches

### Backend (Data + Domain)

- **Data** : Gestion des sources de données (Supabase, Hive)
- **Domain** : Logique métier pure, indépendante de l'UI

### Frontend (Presentation + UI)

- **Presentation** : State management avec Provider
- **UI** : Interface utilisateur (pages, widgets, thème)

## 📚 Documentation

Toute la documentation du projet se trouve dans le dossier `documentation/`.

