import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/quest_repository.dart';
import 'data/repositories/player_repository.dart';
import 'data/repositories/user_repository.dart';
import 'domain/services/notification_service.dart';
import 'presentation/providers/quest_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/equipment_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/cat_provider.dart';
import 'presentation/view_models/theme_view_model.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final statsBox  = await Hive.openBox('playerStats');
  final settingsBox = await Hive.openBox('settings');
  await Hive.openBox('inventory');
  await Hive.openBox('equipment');
  await Hive.openBox('cats');

  await NotificationService.init();

  // Repositories
  final supabase   = Supabase.instance.client;
  final authRepo   = AuthRepository(supabase);
  final userRepo   = UserRepository(supabase);
  final questRepo  = QuestRepository(supabase, userRepo);
  final playerRepo = PlayerRepository(statsBox, supabase);

  // Providers encore nécessaires (pages non encore migrées vers ViewModels)
  final questProvider     = QuestProvider();
  final playerProvider    = PlayerProvider();
  final inventoryProvider = InventoryProvider()..loadInventory();
  final equipmentProvider = EquipmentProvider()..loadEquipment();
  final catProvider       = CatProvider()..loadCats();

  runApp(
    MultiProvider(
      providers: [
        // ViewModels globaux
        ChangeNotifierProvider(create: (_) => ThemeViewModel(settingsBox)),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),

        // Repositories exposés pour injection dans les ViewModels de pages
        Provider<QuestRepository>.value(value: questRepo),
        Provider<PlayerRepository>.value(value: playerRepo),

        // Providers en cours de migration (supprimés à l'Étape 4)
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
