import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/quest_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/theme_provider.dart';
=======
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/quest_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/equipment_provider.dart';
>>>>>>> 8b32b3faebf56148495e42cbb9f47ffda8173a99
import 'app_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  // Initialiser Hive pour le stockage local
=======
  // Charger les variables d'environnement depuis .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('⚠️ Erreur lors du chargement du fichier .env: $e');
    print('💡 Assurez-vous que le fichier .env existe à la racine du projet.');
    print('💡 Vous pouvez copier .env.example en .env et y ajouter vos clés.');
  }

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialiser Hive
>>>>>>> 8b32b3faebf56148495e42cbb9f47ffda8173a99
  await Hive.initFlutter();
  
  // Ouvrir les boxes Hive
  await Hive.openBox('quests');
  await Hive.openBox('playerStats');
  await Hive.openBox('inventory');
  await Hive.openBox('equipment');

  final questProvider = QuestProvider();
  final playerProvider = PlayerProvider();
  
  // Ne pas charger les données ici - elles seront chargées après l'authentification
  // Les données seront chargées dans les pages une fois l'utilisateur connecté

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: questProvider),
        ChangeNotifierProvider.value(value: playerProvider),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..loadInventory('')),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()..loadEquipment('')),
      ],
      child: const SamevaApp(),
    ),
  );
} 
