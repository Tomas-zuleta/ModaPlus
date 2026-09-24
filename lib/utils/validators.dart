class Validators {
  Validators._();

  /// Solo exige que el campo no esté vacío (acepta cualquier valor).
  static String? Function(String?) required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(value.trim())) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirma tu contraseña';
      if (value != original()) return 'Las contraseñas no coinciden';
      return null;
    };
  }
}