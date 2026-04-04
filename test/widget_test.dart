import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Sameva')),
      ),
    );

    expect(find.text('Sameva'), findsOneWidget);
  });
}
