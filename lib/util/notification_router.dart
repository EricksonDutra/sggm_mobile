// lib/util/notification_router.dart

class NotificationRoute {
  final String route;
  final Object? arguments;

  const NotificationRoute(this.route, {this.arguments});
}

NotificationRoute resolveNotificationRoute({
  required String? tipo,
  required String? eventoId,
}) {
  final hasEvento = eventoId != null && eventoId.isNotEmpty;

  switch (tipo) {
    case 'evento':
      return hasEvento
          ? NotificationRoute('/evento_detalhes', arguments: eventoId)
          : const NotificationRoute('/home', arguments: {'tab': 'eventos'});

    case 'escala':
      return NotificationRoute('/home', arguments: {
        'tab': 'escalas',
        if (hasEvento) 'eventoId': eventoId,
      });

    case 'comentario':
      return hasEvento ? NotificationRoute('/evento_detalhes', arguments: eventoId) : const NotificationRoute('/home');

    default:
      return const NotificationRoute('/home');
  }
}
