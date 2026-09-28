import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get _hasSpecial => RegExp(r'[!@#$%^&*]').hasMatch(password);

  int get _score {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;
    return score;
  }

  String get _label {
    if (password.isEmpty) return '';
    if (_score <= 1) return 'Clave baja';
    if (_score == 2 || _score == 3) return 'Clave media';
    return 'Clave alta';
  }

  Color get _color {
    if (password.isEmpty) return Colors.grey.shade300;
    if (_score <= 1) return Colors.red;
    if (_score == 2 || _score == 3) return Colors.orange;
    return AppColors.primary;
  }

  double get _progress {
    if (password.isEmpty) return 0.0;
    return _score / 4;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Barra de progreso
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Requisitos
        _Requirement(text: 'Mínimo 8 caracteres', met: _hasMinLength),
        _Requirement(text: 'Una mayúscula (A-Z)', met: _hasUppercase),
        _Requirement(text: 'Un número (0-9)', met: _hasNumber),
        _Requirement(text: r'Un carácter especial (!@#$%^&*)', met: _hasSpecial),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  final String text;
  final bool met;

  const _Requirement({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? AppColors.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.primary : Colors.grey,
              fontWeight: met ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
