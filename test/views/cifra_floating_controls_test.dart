import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/views/widgets/cifra_floating_controls.dart';
import 'package:sggm/util/cifra_scroll_controller.dart';

void main() {
  group('CifraFloatingControls', () {
    testWidgets('painel começa recolhido, mostra apenas ícone', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            CifraFloatingControls(
              config: const CifraScrollConfig(),
              autoScrollAtivo: false,
              onToggleScroll: () {},
              onFonteMais: () {},
              onFonteMenos: () {},
              onVelocidadeMais: () {},
              onVelocidadeMenos: () {},
            ),
          ]),
        ),
      ));

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byIcon(Icons.text_increase), findsNothing);
    });

    testWidgets('ao tocar no botão, painel expande e mostra controles', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            CifraFloatingControls(
              config: const CifraScrollConfig(),
              autoScrollAtivo: false,
              onToggleScroll: () {},
              onFonteMais: () {},
              onFonteMenos: () {},
              onVelocidadeMais: () {},
              onVelocidadeMenos: () {},
            ),
          ]),
        ),
      ));

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.text_increase), findsOneWidget);
      expect(find.byIcon(Icons.text_decrease), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('mostra ícone pause quando autoScrollAtivo é true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            CifraFloatingControls(
              config: const CifraScrollConfig(),
              autoScrollAtivo: true,
              onToggleScroll: () {},
              onFonteMais: () {},
              onFonteMenos: () {},
              onVelocidadeMais: () {},
              onVelocidadeMenos: () {},
            ),
          ]),
        ),
      ));

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });
  });
}
