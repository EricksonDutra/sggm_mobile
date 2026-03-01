import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Inknut_Antiqua',
      ),
      cursorColor: const Color.fromARGB(255, 6, 124, 41),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF414141),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inknut_Antiqua',
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).primaryColor) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
      ),
    );
  }
}
