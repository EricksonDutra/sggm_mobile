import 'package:flutter/material.dart';
import 'package:sggm/models/comentario.dart';
import 'package:sggm/services/comentario_service.dart';
import 'package:sggm/util/app_logger.dart';

class ComentariosProvider extends ChangeNotifier {
  List<ComentarioPerformance> _comentarios = [];
  bool _isLoading = false;
  String? _erro;
  // ← expõe a última mensagem de erro do criar para a UI mostrar no snackbar
  String? erroUltimaAcao;

  List<ComentarioPerformance> get comentarios => _comentarios;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Future<void> listarPorEvento(int eventoId) async {
    _setLoading(true);
    _erro = null;
    try {
      _comentarios = await ComentarioService.listarPorEvento(eventoId);
    } catch (e) {
      _erro = e.toString();
      AppLogger.error('Erro ao carregar comentários', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> listarPorMusica(int eventoId, int musicaId) async {
    _setLoading(true);
    _erro = null;
    try {
      // ← passa eventoId também para filtrar corretamente
      _comentarios = await ComentarioService.listarPorMusica(eventoId, musicaId);
    } catch (e) {
      _erro = e.toString();
      AppLogger.error('Erro ao carregar comentários por música', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> criar({
    required int eventoId,
    int? musicaId,
    required String texto,
  }) async {
    erroUltimaAcao = null;
    try {
      final novo = await ComentarioService.criar(
        eventoId: eventoId,
        musicaId: musicaId,
        texto: texto,
      );
      _comentarios.insert(0, novo);
      notifyListeners();
      return true;
    } catch (e) {
      // ← armazena a mensagem real do backend (ex: "Comentários só podem ser publicados...")
      erroUltimaAcao = e.toString().replaceFirst('Exception: ', '');
      AppLogger.error('Erro ao criar comentário', e);
      return false;
    }
  }

  Future<bool> editar(int id, String novoTexto) async {
    try {
      final atualizado = await ComentarioService.editar(id, novoTexto);
      final idx = _comentarios.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _comentarios[idx] = atualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      AppLogger.error('Erro ao editar comentário', e);
      return false;
    }
  }

  Future<bool> deletar(int id) async {
    try {
      await ComentarioService.deletar(id);
      _comentarios.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar comentário', e);
      return false;
    }
  }

  Future<void> reagir(int id) async {
    try {
      final resultado = await ComentarioService.reagir(id);
      final idx = _comentarios.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _comentarios[idx] = _comentarios[idx].copyWith(
          totalReacoes: resultado['total_reacoes'],
          euCurto: resultado['adicionada'],
        );
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Erro ao reagir ao comentário', e);
    }
  }

  void limpar() {
    _comentarios = [];
    _erro = null;
    erroUltimaAcao = null;
  }
}
