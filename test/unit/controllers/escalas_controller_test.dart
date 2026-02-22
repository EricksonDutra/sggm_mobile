import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/controllers/escalas_controller.dart';

void main() {
  late EscalasProvider escalasProvider;

  setUp(() {
    escalasProvider = EscalasProvider();
  });

  group('EscalasProvider - Estado inicial', () {
    test('lista de escalas começa vazia', () {
      expect(escalasProvider.escalas, isEmpty);
    });

    test('não está carregando por padrão', () {
      expect(escalasProvider.isLoading, false);
    });

    test('errorMessage é null por padrão', () {
      expect(escalasProvider.errorMessage, null);
    });
  });

  group('EscalasProvider - limpar()', () {
    test('limpa estado completamente', () {
      escalasProvider.limpar();
      expect(escalasProvider.escalas, isEmpty);
      expect(escalasProvider.errorMessage, null);
      expect(escalasProvider.isLoading, false);
    });
  });

  group('EscalasProvider - limparErro()', () {
    test('limpa errorMessage sem exceções', () {
      expect(() => escalasProvider.limparErro(), returnsNormally);
      expect(escalasProvider.errorMessage, null);
    });
  });
}
