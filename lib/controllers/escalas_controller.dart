import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sggm/models/escalas.dart';
import 'package:sggm/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EscalasProvider extends ChangeNotifier {
  List<Escala> _escalas = [];
  final String apiUrl = AppConstants.escalasEndpoint;

  List<Escala> get escalas => _escalas;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', //
    };
  }

  Future<void> listarEscalas() async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _escalas = data.map((item) => Escala.fromJson(item)).toList();
        notifyListeners();
      } else {
        throw Exception('Falha ao carregar escalas: ${response.statusCode}');
      }
    } catch (e) {
      print("Erro ao listar escalas: $e");
      rethrow;
    }
  }

  Future<void> adicionarEscala(Escala escala) async {
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(escala.toJson()),
      );

      if (response.statusCode == 201) {
        final novaEscala = Escala.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _escalas.add(novaEscala);
        notifyListeners();
      } else {
        throw Exception('Falha ao criar escala: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletarEscala(int id) async {
    final headers = await _getHeaders();

    final response = await http.delete(Uri.parse('$apiUrl$id/'), headers: headers);

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      _escalas.removeWhere((escala) => escala.id == id);
      notifyListeners();
    } else {
      throw Exception('Falha ao deletar escala');
    }
  }
}
