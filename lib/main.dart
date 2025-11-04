import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/quest_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avec la configuration par défaut (pour Auth uniquement)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser Hive
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
      child: const App(),
    ),
  );
} 
