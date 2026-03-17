import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'domain/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/quest_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/equipment_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/character_provider.dart';
import 'presentation/providers/cat_provider.dart';
import 'app_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rendu edge-to-edge : l'app s'étend derrière la barre de navigation Android
  // et la barre de statut. Les insets sont ensuite gérés via MediaQuery.viewPadding.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('main: erreur chargement .env: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await Hive.initFlutter();
  await Hive.openBox('quests');
  await Hive.openBox('playerStats');
  await Hive.openBox('settings');
  await Hive.openBox('inventory');
  await Hive.openBox('equipment');
  await Hive.openBox('cats');

  // Notifications locales (best-effort)
  await NotificationService.init();

  final questProvider = QuestProvider();
  final playerProvider = PlayerProvider();
  final inventoryProvider = InventoryProvider()..loadInventory();
  final equipmentProvider = EquipmentProvider()..loadEquipment();
  final catProvider = CatProvider()..loadCats();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: questProvider),
        ChangeNotifierProvider.value(value: playerProvider),
        ChangeNotifierProvider.value(value: inventoryProvider),
        ChangeNotifierProvider.value(value: equipmentProvider),
        ChangeNotifierProvider.value(value: catProvider),
      ],
      child: const SamevaApp(),
    ),
  );
}
