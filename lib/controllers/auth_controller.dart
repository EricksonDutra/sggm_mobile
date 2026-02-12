import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sggm/util/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final String apiUrl = AppConstants.loginEndpoint;

  bool _isAuthenticated = false;
  bool _isLider = false;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLider => _isLider;
  String? get token => _token;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access'];
        _isLider = data['is_lider'] ?? false;
        _isAuthenticated = true;

        // Salva no disco para não precisar logar toda vez (Persistência)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setBool('is_lider', _isLider);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erro Login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isLider = false;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // Tenta recuperar a sessão ao abrir o app
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    _isLider = prefs.getBool('is_lider') ?? false;
    _isAuthenticated = true;
    notifyListeners();
  }
}
