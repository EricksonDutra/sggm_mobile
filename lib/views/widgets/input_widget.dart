import 'package:flutter/material.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String labelText,
  bool obscureText = false,
  FocusNode? focusNode,
  Function(String)? onSubmitted,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    focusNode: focusNode,
    obscureText: obscureText,
    keyboardType: keyboardType,
    onSubmitted: onSubmitted,
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
          color: Colors.deepPurple,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(
          color: Colors.grey.shade700,
        ),
      ),
    ),
    style: const TextStyle(
      color: Colors.white,
      fontFamily: 'Inknut_Antiqua',
    ),
    cursorColor: const Color.fromARGB(255, 6, 124, 41),
  );
}
