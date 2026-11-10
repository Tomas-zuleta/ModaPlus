# Configuración y apariencia

- La app inicia en **modo claro**, independientemente del tema del teléfono.
- Perfil → Configuración permite elegir **Claro**, **Oscuro** o **Según el dispositivo**.
- La elección se guarda localmente con `shared_preferences` y persiste tras reiniciar la app.
- También se guardan preferencias de animaciones, confirmación de eliminación y avisos.
- El menú lateral pasa a usar los colores del tema, en lugar de un fondo oscuro obligatorio.
- La pantalla de configuración usa colores adaptativos de Material 3.
- La migración de pantallas antiguas con colores fijos al modo oscuro es gradual; algunas vistas todavía pueden conservar fondos claros.
- La preferencia de avisos no habilita notificaciones push ni solicita permisos.
- No se ha modificado el repositorio web.
