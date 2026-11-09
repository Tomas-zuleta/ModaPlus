import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import '../utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

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
            title: Text('Medellín, Colombia'),
            subtitle: Text('Dirección exacta pendiente de confirmación del negocio'),
          ),
          const ListTile(
            leading: Icon(Icons.access_time_outlined),
            title: Text('Horario de atención'),
            subtitle: Text('Pendiente de confirmación'),
          ),
          const Divider(height: 35),
          const Text('INFORMACIÓN LEGAL', style: TextStyle(
            color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y condiciones'),
            subtitle: const Text('Borrador de la web, pendiente de aprobación legal'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(Uri.parse(
              'https://github.com/MonsalveGod/ModaPlus/blob/main/docs/legal/terminos_y_condiciones.md'),
              mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 20),
          const Text('ModaPlus móvil · Preferencias locales',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}
