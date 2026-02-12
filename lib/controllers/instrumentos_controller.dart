import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sggm/models/instrumentos.dart';
import 'package:sggm/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstrumentosProvider extends ChangeNotifier {
  List<Instrumento> _instrumentos = [];

  final String apiUrl = AppConstants.instrumentosEndpoint;

  List<Instrumento> get instrumentos => _instrumentos;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> listarInstrumentos() async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _instrumentos = data.map((item) => Instrumento.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Erro listar instrumentos: $e");
    }
  }
}
