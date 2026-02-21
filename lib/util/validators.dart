class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'E-mail obrigatório';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName obrigatório';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Senha obrigatória';
    if (value.length < 6) return 'Senha deve ter ao menos 6 caracteres';
    return null;
  }
}
