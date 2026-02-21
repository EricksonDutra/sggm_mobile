import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/controllers/eventos_controller.dart';

void main() {
  late EventoProvider eventoProvider;

  setUp(() {
    eventoProvider = EventoProvider();
  });

  group('EventoProvider - Estado inicial', () {
    test('lista de eventos começa vazia', () {
      expect(eventoProvider.eventos, isEmpty);
    });

    test('não está carregando por padrão', () {
      expect(eventoProvider.isLoading, false);
    });

    test('errorMessage é null por padrão', () {
      expect(eventoProvider.errorMessage, null);
    });
  });

  group('EventoProvider - limpar()', () {
    test('limpa estado completamente', () {
      eventoProvider.limpar();
      expect(eventoProvider.eventos, isEmpty);
      expect(eventoProvider.errorMessage, null);
      expect(eventoProvider.isLoading, false);
    });
  });

  group('EventoProvider - limparErro()', () {
    test('limpa errorMessage sem exceções', () {
      expect(() => eventoProvider.limparErro(), returnsNormally);
      expect(eventoProvider.errorMessage, null);
    });
  });
}
