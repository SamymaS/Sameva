import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/quest_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/theme_provider.dart';
import 'app_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive pour le stockage local
  await Hive.initFlutter();
  
  // Ouvrir les boxes Hive
  await Hive.openBox('quests');
  await Hive.openBox('playerStats');

  final questProvider = QuestProvider();
  final playerProvider = PlayerProvider();
  
  // Charger les données initiales
  questProvider.loadQuests('');
  playerProvider.loadPlayerStats('');

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
