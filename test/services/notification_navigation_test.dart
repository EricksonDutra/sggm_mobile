import 'package:flutter_test/flutter_test.dart';
import 'package:sggm/util/notification_router.dart';

void main() {
  group('_resolveNotificationRoute', () {
    test('tipo evento com eventoId retorna /evento_detalhes', () {
      final result = resolveNotificationRoute(tipo: 'evento', eventoId: '42');
      expect(result.route, '/evento_detalhes');
      expect(result.arguments, '42');
    });

    test('tipo evento sem eventoId retorna /home', () {
      final result = resolveNotificationRoute(tipo: 'evento', eventoId: null);
      expect(result.route, '/home');
    });

    test('tipo escala com eventoId retorna /home com args', () {
      final result = resolveNotificationRoute(tipo: 'escala', eventoId: '10');
      expect(result.route, '/home');
      expect((result.arguments as Map)['tab'], 'escalas');
      expect((result.arguments as Map)['eventoId'], '10');
    });

    test('tipo desconhecido retorna /home', () {
      final result = resolveNotificationRoute(tipo: 'xyz', eventoId: null);
      expect(result.route, '/home');
    });

    test('tipo null retorna /home', () {
      final result = resolveNotificationRoute(tipo: null, eventoId: null);
      expect(result.route, '/home');
    });
  });
}
