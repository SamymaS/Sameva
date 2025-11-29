# Intégration du Design Figma dans Sameva

## 🎨 Votre Design Figma

**Lien** : [Mockup Sameva - Community](https://www.figma.com/make/LqRoDzdtmLcC2AV2E08ess/Mockup-Sameva--Community---Copy-?node-id=0-1&t=xZq5WkElAlQ4ySP1-1)

## 📱 Pages identifiées dans votre design

D'après `assets/App.tsx`, votre design contient :

1. **Sanctuary** - Page principale (Sanctuaire)
2. **QuestCreation** - Création de quêtes
3. **Marketplace** - Marché
4. **Summoning** - Invocation
5. **Customization** - Personnalisation
6. **MiniGame** - Mini-jeux
7. **Navigation** - Barre de navigation

## 🔄 Correspondance avec l'application Flutter

| Figma Component | Flutter Page | Fichier |
|----------------|--------------|---------|
| Sanctuary | HomePage | `lib/pages/home/new_home_page.dart` |
| Marketplace | MarketPage | `lib/pages/market/market_page.dart` |
| Summoning | InvocationPage | `lib/pages/invocation/invocation_page.dart` |
| Customization | AvatarPage | `lib/pages/avatar/avatar_page.dart` |
| MiniGame | MiniGamePage | `lib/pages/minigame/minigame_page.dart` |
| QuestCreation | CreateQuestPage | `lib/pages/quest/fantasy_create_quest_page.dart` |

## 📥 Étapes pour exporter depuis Figma

### 1. Exporter les images des composants

Pour chaque composant dans Figma :

#### Avatars (Customization)
1. Sélectionnez tous les avatars
2. Export → PNG @1x, @2x, @3x
3. Nommez : `hero_base.png`, `hero_1.png`, etc.
4. Placez dans `assets/images/avatars/`

#### Items (Marketplace)
1. Sélectionnez chaque item du marché
2. Export → PNG @2x (pour qualité)
3. Nommez selon le nom de l'item (ex: `heaume_du_zénith.png`)
4. Placez dans `assets/images/items/`

#### Backgrounds
1. Sélectionnez les backgrounds de chaque page
2. Export → PNG ou WebP
3. Nommez : `home_background.png`, `market_background.png`, etc.
4. Placez dans `assets/images/backgrounds/`

### 2. Extraire les couleurs

Dans Figma :
1. Ouvrez le panneau **Design** → **Styles**
2. Notez toutes les couleurs utilisées
3. Vérifiez `lib/theme/app_colors.dart` et ajustez si nécessaire

### 3. Extraire les espacements et tailles

Notez dans Figma :
- Les paddings/margins utilisés
- Les tailles de police
- Les border-radius
- Les ombres

Ces valeurs sont déjà intégrées dans les widgets Flutter, mais vous pouvez les ajuster.

## 🛠️ Utilisation du helper

J'ai créé `lib/utils/figma_assets_helper.dart` pour faciliter l'utilisation des assets :

```dart
import '../../utils/figma_assets_helper.dart';

// Utiliser un asset
Image.asset(FigmaAssets.avatarBase)

// Obtenir un item par nom
Image.asset(FigmaAssets.getItemPath('Heaume du Zénith'))

// Obtenir un avatar par index
Image.asset(FigmaAssets.getAvatarPath(1))
```

## 📋 Checklist d'intégration

### Images à exporter
- [ ] Avatars (depuis Customization)
- [ ] Items du marché (depuis Marketplace)
- [ ] Backgrounds pour chaque page
- [ ] Compagnons (depuis Customization)
- [ ] Auras (depuis Customization)
- [ ] Icônes des mini-jeux (depuis MiniGame)

### Vérifications
- [ ] Toutes les images sont dans les bons dossiers
- [ ] Les noms de fichiers correspondent aux noms dans le code
- [ ] Les couleurs dans `app_colors.dart` correspondent à Figma
- [ ] Les espacements sont cohérents avec le design

## 🎯 Prochaines étapes

1. **Exporter les assets** depuis Figma selon le guide `GUIDE_EXPORT_FIGMA.md`
2. **Placer les fichiers** dans les dossiers appropriés
3. **Tester l'application** pour vérifier que les images s'affichent
4. **Ajuster les layouts** si nécessaire pour correspondre exactement au design

## 💡 Conseils

- Exportez toujours en haute résolution (@2x ou @3x)
- Utilisez des noms de fichiers cohérents (minuscules, underscores)
- Testez sur différents appareils pour vérifier l'affichage
- Compressez les images si elles sont trop lourdes

## 🔗 Ressources

- Guide d'export : `GUIDE_EXPORT_FIGMA.md`
- Helper assets : `lib/utils/figma_assets_helper.dart`
- Documentation Flutter Assets : https://docs.flutter.dev/development/ui/assets-and-images





