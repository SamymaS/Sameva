import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sameva/presentation/view_models/theme_view_model.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await Hive.initFlutter();
    final settingsBox = await Hive.openBox('settings');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeViewModel(settingsBox)),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Sameva'))),
      ),
    );

    expect(find.text('Sameva'), findsOneWidget);
  });
}
