import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/views/widgets/buttons/app_button.dart';

// Helper para montar o widget isolado
Widget _buildApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AppButton', () {
    // ─── VARIANT: primary ────────────────────────────────────────────
    group('variant primary', () {
      testWidgets('renderiza ElevatedButton por padrão', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', onPressed: () {}),
        ));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('exibe o label corretamente', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', onPressed: () {}),
        ));
        expect(find.text('Salvar'), findsOneWidget);
      });
    });

    // ─── VARIANT: secondary ──────────────────────────────────────────
    group('variant secondary', () {
      testWidgets('renderiza OutlinedButton', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Cancelar',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ));
        expect(find.byType(OutlinedButton), findsOneWidget);
      });
    });

    // ─── VARIANT: danger ─────────────────────────────────────────────
    group('variant danger', () {
      testWidgets('renderiza ElevatedButton', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Excluir',
            variant: AppButtonVariant.danger,
            onPressed: () {},
          ),
        ));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    // ─── VARIANT: ghost ──────────────────────────────────────────────
    group('variant ghost', () {
      testWidgets('renderiza TextButton', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Voltar',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
          ),
        ));
        expect(find.byType(TextButton), findsOneWidget);
      });
    });

    // ─── TAMANHOS / ALTURA ────────────────────────────────────────────
    group('tamanhos', () {
      testWidgets('size small tem altura 40', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Btn',
            size: AppButtonSize.small,
            onPressed: () {},
          ),
        ));
        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(AppButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.height, 40.0);
      });

      testWidgets('size medium tem altura 52 (padrão)', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Btn', onPressed: () {}),
        ));
        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(AppButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.height, 52.0);
      });

      testWidgets('size large tem altura 60', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Btn',
            size: AppButtonSize.large,
            onPressed: () {},
          ),
        ));
        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(AppButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.height, 60.0);
      });
    });

    // ─── fullWidth ────────────────────────────────────────────────────
    group('fullWidth', () {
      testWidgets('fullWidth true → SizedBox.width é double.infinity', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Btn', onPressed: () {}, fullWidth: true),
        ));
        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(AppButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.width, double.infinity);
      });

      testWidgets('fullWidth false → SizedBox.width é null', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Btn', onPressed: () {}, fullWidth: false),
        ));
        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(AppButton),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.width, isNull);
      });
    });

    // ─── ESTADO DESABILITADO ──────────────────────────────────────────
    group('estado desabilitado', () {
      testWidgets('onPressed null desabilita o botão', (tester) async {
        await tester.pumpWidget(_buildApp(
          const AppButton(label: 'Salvar', onPressed: null),
        ));
        final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(btn.onPressed, isNull);
      });

      testWidgets('isLoading true desabilita o botão', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', isLoading: true, onPressed: () {}),
        ));
        final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(btn.onPressed, isNull);
      });
    });

    // ─── ESTADO DE LOADING ────────────────────────────────────────────
    group('estado de loading', () {
      testWidgets('isLoading true exibe CircularProgressIndicator', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', isLoading: true, onPressed: () {}),
        ));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('isLoading true NÃO exibe o label', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', isLoading: true, onPressed: () {}),
        ));
        expect(find.text('Salvar'), findsNothing);
      });

      testWidgets('isLoading false exibe o label normalmente', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', isLoading: false, onPressed: () {}),
        ));
        expect(find.text('Salvar'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    // ─── ÍCONE ────────────────────────────────────────────────────────
    group('ícone', () {
      testWidgets('icon não nulo exibe Icon widget', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(
            label: 'Salvar',
            icon: Icons.save,
            onPressed: () {},
          ),
        ));
        expect(find.byIcon(Icons.save), findsOneWidget);
      });

      testWidgets('icon nulo NÃO exibe Icon widget', (tester) async {
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', onPressed: () {}),
        ));
        expect(find.byType(Icon), findsNothing);
      });
    });

    // ─── CALLBACK ─────────────────────────────────────────────────────
    group('callback', () {
      testWidgets('chama onPressed ao tocar', (tester) async {
        var chamado = false;
        await tester.pumpWidget(_buildApp(
          AppButton(label: 'Salvar', onPressed: () => chamado = true),
        ));
        await tester.tap(find.byType(ElevatedButton));
        expect(chamado, isTrue);
      });

      testWidgets('NÃO chama onPressed quando desabilitado', (tester) async {
        var chamado = false;
        await tester.pumpWidget(_buildApp(
          const AppButton(label: 'Salvar', onPressed: null),
        ));
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        expect(chamado, isFalse);
      });
    });
  });

  group('textStyle', () {
    testWidgets('textStyle customizado é aplicado ao label', (tester) async {
      const style = TextStyle(fontFamily: 'Inknut_Antiqua', fontSize: 18);
      await tester.pumpWidget(_buildApp(
        AppButton(label: 'Entrar', onPressed: () {}, textStyle: style),
      ));
      final text = tester.widget<Text>(find.text('Entrar'));
      expect(text.style?.fontFamily, 'Inknut_Antiqua');
    });
  });
}
