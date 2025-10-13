import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'config/env_config.dart';
import 'services/openai_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/quest_provider.dart';
import 'core/providers/player_provider.dart';
import 'core/providers/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement (.env)
  await EnvConfig.initialize();

  // Initialiser Firebase avec la configuration par défaut
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser Hive
  await Hive.initFlutter();

  // Initialiser OpenAI si la clé est disponible
  if (EnvConfig.openAIApiKey.isNotEmpty) {
    OpenAIService.initialize(EnvConfig.openAIApiKey);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuestProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const App(),
    ),
  );
} 
