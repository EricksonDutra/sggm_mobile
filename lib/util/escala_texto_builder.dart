import 'package:sggm/models/escalas.dart';
import 'package:sggm/models/eventos.dart';
import 'package:sggm/util/date_formatter.dart';

class EscalaTextoBuilder {
  static String gerar({
    required Evento evento,
    required List<Escala> escalas,
  }) {
    final sb = StringBuffer();

    // Cabeçalho
    sb.writeln('*${evento.nome.toUpperCase()}*');
    if (evento.tipo.isNotEmpty) sb.writeln('🎵 Tipo: ${evento.tipo}');
    sb.writeln('🗓 Data: ${DateFormatter.fromIso(evento.dataEvento)}');

    if (evento.dataEvento.contains('T')) {
      final horario = evento.dataEvento.split('T')[1].substring(0, 5);
      sb.writeln('🕐 Horário: $horario');
    }

    sb.writeln('📍 Local: ${evento.local}');

    if (evento.descricao != null && evento.descricao!.trim().isNotEmpty) {
      sb.writeln('📝 ${evento.descricao}');
    }
    sb.writeln('');

    // Ensaio
    if (evento.dataHoraEnsaio != null) {
      sb.writeln('*ENSAIO:*');
      sb.writeln('📅 ${DateFormatter.dataHoraFromDateTime(evento.dataHoraEnsaio!)}');
      sb.writeln('');
    }

    // Banda
    sb.writeln('*BANDA:*');
    if (escalas.isEmpty) {
      sb.writeln('(Ninguém escalado)');
    } else {
      final confirmados = escalas.where((e) => e.confirmado).toList();
      final pendentes = escalas.where((e) => !e.confirmado).toList();

      for (final e in confirmados) {
        sb.writeln('✅ ${e.musicoNome ?? "Músico"} (${e.instrumentoNome ?? "Não especificado"})');
      }
      for (final e in pendentes) {
        sb.writeln('⏳ ${e.musicoNome ?? "Músico"} (${e.instrumentoNome ?? "Não especificado"})');
      }

      final comObs = escalas.where((e) => e.observacao != null && e.observacao!.trim().isNotEmpty);
      if (comObs.isNotEmpty) {
        sb.writeln('');
        sb.writeln('_Obs:_');
        for (final e in comObs) {
          sb.writeln('• ${e.musicoNome ?? "Músico"}: ${e.observacao}');
        }
      }
    }
    sb.writeln('');

    // Repertório
    sb.writeln('*REPERTÓRIO:*');
    final musicas = evento.repertorio ?? [];
    if (musicas.isEmpty) {
      sb.writeln('(A definir)');
    } else {
      for (var i = 0; i < musicas.length; i++) {
        final m = musicas[i];
        sb.writeln('${i + 1}. *${m.titulo}* - ${m.artistaNome} [Tom: ${m.tom ?? "?"}]');
        if (m.linkYoutube != null && m.linkYoutube!.isNotEmpty) {
          sb.writeln('   🎬 ${m.linkYoutube}');
        }
      }
    }
    sb.writeln('');

    sb.writeln('_Enviado pelo app SGGM_ 🎶');

    return sb.toString();
  }
}
