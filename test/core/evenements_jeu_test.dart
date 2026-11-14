import 'package:flutter_test/flutter_test.dart';
import 'package:sameva/core/audio/sons.dart';
import 'package:sameva/core/evenements/ambiance.dart';
import 'package:sameva/core/evenements/evenements_jeu.dart';

void main() {
  test('le bus livre les événements à tous les abonnés', () {
    final a = <EvenementJeu>[], b = <TypeEvenement>[];
    final s1 = BusJeu.flux.listen(a.add);
    final s2 = BusJeu.flux.listen((e) => b.add(e.type));
    BusJeu.emettre(TypeEvenement.queteAccomplie);
    BusJeu.emettre(TypeEvenement.invocation, rarete: 'epic');
    expect(a.map((e) => e.type), [TypeEvenement.queteAccomplie, TypeEvenement.invocation]);
    expect(a.last.rarete, 'epic');
    expect(b, hasLength(2));
    s1.cancel();
    s2.cancel();
  });

  test('émettre sans abonné ne fait rien (écrans testés isolément)', () {
    expect(() => BusJeu.emettre(TypeEvenement.toucher), returnsNormally);
  });

  group('table des sons', () {
    test('chaque événement a un son', () {
      for (final t in TypeEvenement.values) {
        expect(Ambiance.sonPour(EvenementJeu(t)), isNotNull, reason: t.name);
      }
    });

    test('l\'invocation suit la rareté', () {
      Son? son(String r) => Ambiance.sonPour(EvenementJeu(TypeEvenement.invocation, rarete: r));
      expect(son('common'), Son.invocationCommune);
      expect(son('epic'), Son.invocationRare);
      expect(son('legendary'), Son.invocationLegendaire);
      expect(Ambiance.sonPour(const EvenementJeu(TypeEvenement.invocation)), Son.invocationCommune);
    });
  });

  group('table des vibrations', () {
    test('discrète pour l\'interface, marquée pour les moments forts', () {
      Vibration v(TypeEvenement t, [String? r]) => Ambiance.vibrationPour(EvenementJeu(t, rarete: r));
      expect(v(TypeEvenement.toucher), Vibration.aucune);
      expect(v(TypeEvenement.pieceGagnee), Vibration.legere);
      expect(v(TypeEvenement.queteAccomplie), Vibration.moyenne);
      expect(v(TypeEvenement.niveauSuperieur), Vibration.forte);
      expect(v(TypeEvenement.oracleRefuse), Vibration.forte);
      expect(v(TypeEvenement.invocation, 'common'), Vibration.legere);
      expect(v(TypeEvenement.invocation, 'legendary'), Vibration.forte);
    });
  });
}
