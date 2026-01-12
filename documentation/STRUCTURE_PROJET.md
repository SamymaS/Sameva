# Structure Professionnelle du Projet Sameva

## 📁 Architecture Backend/Frontend

```
lib/
├── main.dart                    # Point d'entrée
├── app_new.dart                 # Configuration de l'application
│
├── data/                        # BACKEND - Couche de données
│   ├── datasources/            # Sources de données (Supabase, Hive)
│   │   ├── local/              # Stockage local (Hive)
│   │   └── remote/             # API distante (Supabase)
│   ├── repositories/            # Repositories (abstraction des datasources)
│   │   ├── quest_repository.dart
│   │   ├── user_repository.dart
│   │   ├── inventory_repository.dart
│   │   └── equipment_repository.dart
│   └── models/                 # Modèles de données (DTO)
│       ├── quest_model.dart
│       ├── user_model.dart
│       ├── item_model.dart
│       └── equipment_model.dart
│
├── domain/                      # BACKEND - Logique métier
│   ├── entities/                # Entités du domaine
│   │   ├── quest.dart
│   │   ├── user.dart
│   │   ├── item.dart
│   │   └── equipment.dart
│   ├── repositories/            # Interfaces des repositories
│   └── services/                # Services métier
│       ├── quest_service.dart
│       ├── reward_calculator.dart
│       ├── bonus_malus_service.dart
│       └── item_factory.dart
│
├── presentation/                # FRONTEND - Couche de présentation
│   ├── providers/               # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── quest_provider.dart
│   │   ├── player_provider.dart
│   │   ├── inventory_provider.dart
│   │   ├── equipment_provider.dart
│   │   └── theme_provider.dart
│   └── viewmodels/              # ViewModels (optionnel)
│
├── ui/                          # FRONTEND - Interface utilisateur
│   ├── pages/                   # Pages de l'application
│   │   ├── auth/
│   │   ├── home/
│   │   ├── quest/
│   │   ├── profile/
│   │   ├── inventory/
│   │   ├── market/
│   │   ├── minigame/
│   │   └── ...
│   ├── widgets/                 # Widgets réutilisables
│   │   ├── common/              # Widgets communs
│   │   ├── animations/          # Animations
│   │   ├── fantasy/             # Widgets fantasy
│   │   └── ...
│   └── theme/                   # Thème et styles
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_styles.dart
│
└── config/                      # Configuration
    └── supabase_config.dart
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

## 📝 Principes

1. **Séparation des responsabilités** : Chaque couche a un rôle précis
2. **Dépendances unidirectionnelles** : UI → Presentation → Domain → Data
3. **Abstraction** : Les repositories sont des interfaces dans domain
4. **Réutilisabilité** : Les services métier sont indépendants de l'UI

