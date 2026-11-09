import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import '../utils/app_colors.dart';
import 'legal_draft_page.dart';
import 'project_policies_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferences.instance;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('CONFIGURACIÓN')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('PERSONALIZA TU EXPERIENCIA',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Tus preferencias se guardan en este dispositivo.'),
          const SizedBox(height: 26),
          const Text('APARIENCIA', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...[
            (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
            (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
            (ThemeMode.system, 'Según el dispositivo', Icons.phone_android_rounded),
          ].map((option) => RadioListTile<ThemeMode>(
            title: Text(option.$2),
            secondary: Icon(option.$3),
            value: option.$1,
            groupValue: preferences.themeMode,
            onChanged: (value) {
              if (value != null) preferences.setThemeMode(value);
            },
          )),
          const Divider(height: 35),
          const Text('PREFERENCIAS', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          SwitchListTile(
            title: const Text('Animaciones'),
            subtitle: const Text('Permitir transiciones y movimientos'),
            secondary: const Icon(Icons.animation_rounded),
            value: preferences.animations,
            onChanged: preferences.setAnimations,
          ),
          SwitchListTile(
            title: const Text('Confirmar al eliminar'),
            subtitle: const Text('Pedir confirmación antes de quitar productos'),
            secondary: const Icon(Icons.delete_outline_rounded),
            value: preferences.confirmRemove,
            onChanged: preferences.setConfirmRemove,
          ),
          SwitchListTile(
            title: const Text('Avisos en la aplicación'),
            subtitle: const Text('Preferencia guardada; avisos remotos aún no disponibles'),
            secondary: const Icon(Icons.notifications_outlined),
            value: preferences.notifications,
            onChanged: preferences.setNotifications,
          ),
          const Divider(height: 35),
          const Text('INFORMACIÓN DEL LOCAL', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const ListTile(
            leading: Icon(Icons.location_city_outlined),
            title: Text('Parque principal de San Cristóbal'),
            subtitle: Text('Referencia de ubicación indicada en la ficha técnica aprobada. No corresponde a una dirección postal exacta.'),
          ),
          const ListTile(
            leading: Icon(Icons.access_time_outlined),
            title: Text('Horario de atención'),
            subtitle: Text('Pendiente de confirmación'),
          ),
          const Divider(height: 35),
          const Text('POLÍTICAS DEL PROYECTO', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ListTile(
            leading: const Icon(Icons.rule_outlined),
            title: const Text('Reglas de pedidos y Plan Separe'),
            subtitle: const Text('Resumen de la ficha técnica aprobada; sujeto a validación legal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProjectPoliciesPage())),
          ),
          const Divider(height: 35),
          const Text('INFORMACIÓN LEGAL', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y condiciones'),
            subtitle: const Text('Versión demostrativa, pendiente de aprobación legal'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const LegalDraftPage())),
          ),
          const SizedBox(height: 20),
          const Text('ModaPlus móvil · Preferencias locales',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
