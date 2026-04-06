import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/repositories/auth_repository.dart';
import 'package:sameva/presentation/view_models/auth_view_model.dart';
import 'package:sameva/ui/pages/auth/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('LoginPage se rend sans erreur', (WidgetTester tester) async {
    final repo = _MockAuthRepository();
    when(() => repo.currentUser).thenReturn(null);
    when(() => repo.authStateChanges)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    final vm = AuthViewModel(repo);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: vm,
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
