import 'package:flutter/material.dart';

Widget buildTextField( {required TextEditingController controller, required String labelText, bool obscureText = false}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      labelText: labelText,
      filled: true,
      fillColor: const Color(0xFF414141),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inknut_Antiqua',
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(
          color: Colors.grey,
        ),
      ),
    ),
    style: const TextStyle(
      color: Colors.white,
      fontFamily: 'Inknut_Antiqua',
    ), // Cor do texto inserido pelo usuário
    cursorColor: const Color.fromARGB(255, 6, 124, 41), // Cor do cursor
  );
}
