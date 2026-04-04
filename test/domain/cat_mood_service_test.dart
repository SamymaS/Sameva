import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/domain/services/cat_mood_service.dart';

void main() {
  group('CatMoodService', () {
    group('getMoodExpression', () {
      test('devrait retourner excited si streak >= 7 et moral élevé', () {
        expect(
          CatMoodService.getMoodExpression(0.85, 7),
          CatMood.excited,
        );
      });

      test('devrait retourner happy si moral >= 0.70 sans streak 7', () {
        expect(
          CatMoodService.getMoodExpression(0.75, 3),
          CatMood.happy,
        );
      });

      test('devrait retourner neutral pour moral moyen', () {
        expect(
          CatMoodService.getMoodExpression(0.5, 0),
          CatMood.neutral,
        );
      });

      test('devrait retourner sad pour moral bas', () {
        expect(
          CatMoodService.getMoodExpression(0.25, 0),
          CatMood.sad,
        );
      });

      test('devrait retourner sleepy pour moral très bas', () {
        expect(
          CatMoodService.getMoodExpression(0.1, 0),
          CatMood.sleepy,
        );
      });
    });

    group('getIdleAnimation', () {
      test('devrait mapper chaque humeur à une clé d\'animation', () {
        expect(CatMoodService.getIdleAnimation(CatMood.excited), 'cat_excited');
        expect(CatMoodService.getIdleAnimation(CatMood.happy), 'cat_happy');
        expect(CatMoodService.getIdleAnimation(CatMood.neutral), 'cat_idle');
        expect(CatMoodService.getIdleAnimation(CatMood.sad), 'cat_sad');
        expect(CatMoodService.getIdleAnimation(CatMood.sleepy), 'cat_sleepy');
      });
    });

    group('getBubbleMessage', () {
      test('devrait inclure le streak pour excited longue série', () {
        final msg = CatMoodService.getBubbleMessage(CatMood.excited, 30);
        expect(msg, contains('30'));
        expect(msg, isNotEmpty);
      });

      test('devrait retourner un message stable pour neutral', () {
        final msg = CatMoodService.getBubbleMessage(CatMood.neutral, 0);
        expect(msg, contains('quête'));
      });
    });

    group('getCatReactionMessage', () {
      test('devrait varier selon perfect / late / success', () {
        final perfect = CatMoodService.getCatReactionMessage(
          CatMood.happy,
          'perfect',
        );
        final late = CatMoodService.getCatReactionMessage(
          CatMood.happy,
          'late',
        );
        final success = CatMoodService.getCatReactionMessage(
          CatMood.happy,
          'success',
        );
        expect(perfect, isNot(equals(late)));
        expect(success, isNot(equals(perfect)));
      });
    });

    group('moodEmoji et moodLabel', () {
      test('devrait exposer emoji et label pour chaque humeur', () {
        for (final m in CatMood.values) {
          expect(CatMoodService.moodEmoji(m), isNotEmpty);
          expect(CatMoodService.moodLabel(m), isNotEmpty);
        }
      });
    });
  });
}
