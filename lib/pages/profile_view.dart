import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/user_role.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import 'auth_page.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _docCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  void _startEdit() {
    final s = AppStore.instance.session;
    _nombresCtrl.text = s?.nombres ?? '';
    _apellidosCtrl.text = s?.apellidos ?? '';
    _docCtrl.text = s?.identificacion ?? '';
    _phoneCtrl.text = s?.phone ?? '';
    _addressCtrl.text = s?.direccion ?? '';
    setState(() => _editing = true);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    AppStore.instance.updateProfile(
      nombres: _nombresCtrl.text.trim(),
      apellidos: _apellidosCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      direccion: _addressCtrl.text.trim(),
      identificacion: _docCtrl.text.trim(),
    );
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
  }

  void _logout() {
    AppStore.instance.endSession();
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(const AuthPage(), duration: const Duration(milliseconds: 500)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.session;
        if (s == null) return const SizedBox.shrink();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Text(
                      _initials(s.name),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).stagger(0),
                const SizedBox(height: 16),
                Text(
                  s.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).stagger(1),
                const SizedBox(height: 8),
                Center(
                  child: StatusChip(
                    label: s.role == UserRole.admin ? 'Administrador' : 'Cliente',
                    color: AppColors.primary,
                  ),
                ).stagger(2),
                const SizedBox(height: 28),
                SectionCard(
                  title: 'INFORMACIÓN PERSONAL',
                  child: _editing
                      ? Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              InfoRow(label: 'Correo', value: s.email),
                              const SizedBox(height: 12),
                              AuthTextField(
                                label: 'Nombres',
                                controller: _nombresCtrl,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Ingresa tus nombres'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: 'Apellidos',
                                controller: _apellidosCtrl,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Ingresa tus apellidos'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: 'Documento de identidad',
                                controller: _docCtrl,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Ingresa tu documento'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: 'Teléfono',
                                hint: '3001234567',
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.isEmpty) return null;
                                  return RegExp(r'^\d{7,10}$').hasMatch(t)
                                      ? null
                                      : 'Teléfono no válido';
                                },
                              ),
                              const SizedBox(height: 20),
                              AuthTextField(
                                label: 'Dirección',
                                hint: 'Calle 10 # 20-30',
                                controller: _addressCtrl,
                                textInputAction: TextInputAction.done,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            InfoRow(label: 'Nombres', value: s.nombres),
                            InfoRow(
                              label: 'Apellidos',
                              value: s.apellidos.isEmpty ? 'No registrado' : s.apellidos,
                            ),
                            InfoRow(label: 'Correo', value: s.email),
                            InfoRow(
                              label: 'Documento',
                              value: s.identificacion ?? 'No registrado',
                            ),
                            InfoRow(
                              label: 'Teléfono',
                              value: s.phone.isEmpty ? 'No registrado' : s.phone,
                            ),
                            InfoRow(
                              label: 'Dirección',
                              value: s.direccion.isEmpty ? 'No registrada' : s.direccion,
                            ),
                          ],
                        ),
                ).stagger(3),
                const SizedBox(height: 20),
                if (_editing) ...[
                  PrimaryButton(text: 'Guardar cambios', onPressed: _save),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text('Cancelar',
                        style: TextStyle(color: AppColors.slate)),
                  ),
                ] else ...[
                  PrimaryButton(text: 'Editar perfil', onPressed: _startEdit)
                      .stagger(4),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.textDark),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text(
                        'CERRAR SESIÓN',
                        style: TextStyle(letterSpacing: 2),
                      ),
                    ),
                  ).stagger(5),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}