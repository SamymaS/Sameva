import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sameva/data/models/quest_model.dart';
import 'package:sameva/data/repositories/game_api.dart';
import 'package:sameva/presentation/view_models/ai_validation_credits_service.dart';
import 'package:sameva/ui/pages/quest/quest_validation_page.dart';

class _MockBox extends Mock implements Box<dynamic> {}

/// Défi de capture : affiché avant la photo, relançable une seule fois.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late List<Map<String, dynamic>> challengeCalls;
  var gestures = <String>['un pouce levé', 'deux doigts en V'];

  GameApi fakeApi() {
    challengeCalls = [];
    var n = 0;
    return GameApi.withTransport(
      rpc: (fn, params) async {
        expect(fn, 'oracle_challenge');
        challengeCalls.add(params);
        final gesture = gestures[n.clamp(0, gestures.length - 1)];
        final reroll = params['p_reroll'] == true;
        n++;
        return {
          'challenge_id': 'c$n',
          'label': '$gesture, et le nombre ${40 + n} écrit sur un papier',
          'gesture': gesture,
          'number': '${40 + n}',
          'hands_free': false,
          'expires_in': 180,
          'rerolls_left': reroll ? 0 : 1,
        };
      },
      function: (_, __) async => throw UnimplementedError(),
    );
  }

  Widget build(GameApi api) {
    final box = _MockBox();
    when(() => box.get(any())).thenReturn(null);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
    final quest = Quest(
      id: 'q1',
      userId: 'u1',
      title: 'Ranger ma chambre',
      estimatedDurationMinutes: 20,
      frequency: QuestFrequency.oneOff,
      difficulty: 2,
      category: 'Maison',
      rarity: QuestRarity.common,
      status: QuestStatus.active,
      validationType: ValidationType.photo,
      createdAt: DateTime.now(),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AiValidationCreditsService>.value(value: AiValidationCreditsService(box)),
      ],
      child: MaterialApp(home: QuestValidationPage(quest: quest, gameApi: api)),
    );
  }

  testWidgets('le défi tiré par le serveur est affiché dès l\'ouverture', (tester) async {
    gestures = ['un pouce levé', 'deux doigts en V'];
    await tester.pumpWidget(build(fakeApi()));
    await tester.pump();
    await tester.pump();

    expect(challengeCalls.single, {'p_quest_id': 'q1', 'p_reroll': false});
    expect(find.text('un pouce levé'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.textContaining('vient d\'être prise'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('« Changer de défi » ne sert qu\'une fois', (tester) async {
    gestures = ['un pouce levé', 'deux doigts en V'];
    await tester.pumpWidget(build(fakeApi()));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Changer de défi (une fois)'));
    await tester.pump();
    await tester.pump();

    expect(challengeCalls.last['p_reroll'], isTrue);
    expect(find.text('deux doigts en V'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Changer de défi (une fois)'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
