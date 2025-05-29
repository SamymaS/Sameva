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

  // Initialiser Firebase avec la configuration par défaut
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser Hive
  await Hive.initFlutter();

  // OpenAI sera configuré plus tard
  // await OpenAIService.initialize('VOTRE_CLE_API');

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
