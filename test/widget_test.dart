// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sameva/main.dart';
import 'package:sameva/core/providers/auth_provider.dart';
import 'package:sameva/core/providers/quest_provider.dart';
import 'package:sameva/core/providers/player_provider.dart';
import 'package:sameva/core/providers/theme_provider.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Initialiser Hive pour les tests
    await Hive.initFlutter();
    await Hive.openBox('quests');
    await Hive.openBox('playerStats');
    
    final questProvider = QuestProvider();
    final playerProvider = PlayerProvider();
    
    questProvider.loadQuests('');
    playerProvider.loadPlayerStats('');
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: questProvider),
          ChangeNotifierProvider.value(value: playerProvider),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Sameva'))),
      ),
    );

    // Verify that the app starts
    expect(find.text('Sameva'), findsOneWidget);
  });
}
