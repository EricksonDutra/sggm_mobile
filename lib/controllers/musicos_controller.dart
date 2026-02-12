import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sggm/models/musicos.dart';
import 'package:sggm/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicosProvider extends ChangeNotifier {
  List<Musico> _musicos = [];
  final String apiUrl = AppConstants.musicosEndpoint;

  List<Musico> get musicos => _musicos;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', //
    };
  }

  Future<void> listarMusicos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _musicos = data.map((item) => Musico.fromJson(item)).toList();
        notifyListeners();
      } else {
        throw Exception('Falha ao carregar músicos: ${response.statusCode}');
      }
    } catch (e) {
      print("Erro listar músicos: $e");
      rethrow;
    }
  }

  Future<void> adicionarMusico(Musico musico) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(musico.toJson()),
      );

      if (response.statusCode == 201) {
        final novoMusico = Musico.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _musicos.add(novoMusico);
        notifyListeners();
      } else {
        throw Exception('Falha ao adicionar: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atualizarMusico(int id, Musico novoMusico) async {
    final headers = await _getHeaders();

    final response = await http.put(
      Uri.parse('$apiUrl$id/'), // Atenção à barra no final
      headers: headers,
      body: json.encode(novoMusico.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      final index = _musicos.indexWhere((musico) => musico.id == id);
      if (index != -1) {
        _musicos[index] = novoMusico;
        notifyListeners();
      }
    } else {
      throw Exception('Falha ao atualizar músico: ${response.body}');
    }
  }

  Future<void> deletarMusico(int id) async {
    final headers = await _getHeaders();

    final response = await http.delete(Uri.parse('$apiUrl$id/'), headers: headers);

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      _musicos.removeWhere((musico) => musico.id == id);
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar músico');
    }
  }
}
