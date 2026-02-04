import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/quest_provider.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'app_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('⚠️ Erreur lors du chargement du fichier .env: $e');
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await Hive.initFlutter();
  await Hive.openBox('quests');
  await Hive.openBox('playerStats');
  await Hive.openBox('settings');

  final questProvider = QuestProvider();
  final playerProvider = PlayerProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: questProvider),
        ChangeNotifierProvider.value(value: playerProvider),
      ],
      child: const SamevaApp(),
    ),
  );
} 
