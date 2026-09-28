class Validators {
  Validators._();

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
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Ingresa un correo válido (ej: usuario@email.com)';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe tener al menos una mayúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Debe tener al menos un número';
    final specialChars = '!@#\$%^&*';
    final hasSpecial = specialChars.split('').any((c) => value.contains(c));
    if (!hasSpecial) {
      return 'Debe tener al menos un carácter especial (!@#\$%^&*)';
    }
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
