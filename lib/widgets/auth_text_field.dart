import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  const AuthTextField({super.key, required this.label, required this.controller, this.hint, this.isPassword = false, this.keyboardType = TextInputType.text, this.textInputAction = TextInputAction.next, this.validator});
  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}
class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure = widget.isPassword;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textDark)),
    const SizedBox(height: 9),
    TextFormField(
      controller: widget.controller, obscureText: _obscure, keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction, validator: widget.validator, cursorColor: AppColors.primary,
      style: const TextStyle(fontSize: 15, color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true, fillColor: AppColors.background, hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.error, width: 2)),
        suffixIcon: widget.isPassword ? IconButton(tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña', icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.textMuted), onPressed: () => setState(() => _obscure = !_obscure)) : null,
      ),
    ),
  ]);
}
