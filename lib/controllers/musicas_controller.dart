import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sggm/models/musicas.dart';
import 'package:sggm/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicasProvider extends ChangeNotifier {
  List<Musica> _musicas = [];

  final String apiUrl = AppConstants.musicasEndpoint;

  List<Musica> get musicos => _musicas;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', //
    };
  }

  Future<void> listarMusicas() async {
    final headers = await _getHeaders();
    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _musicas = data.map((item) => Musica.fromJson(item)).toList();
        notifyListeners();
      } else {
        throw Exception('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      print("Erro Provider Músicas: $e");
      rethrow;
    }
  }

  Future<void> adicionarMusica(Musica musica) async {
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(musica.toJson()),
      );

      if (response.statusCode == 201) {
        final novaMusica = Musica.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _musicas.add(novaMusica);
        notifyListeners();
      } else {
        throw Exception('Falha ao adicionar: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletarMusica(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$apiUrl$id/'), headers: headers);
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      _musicas.removeWhere((m) => m.id == id);
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar música');
    }
  }
}
