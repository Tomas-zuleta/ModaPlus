# Autenticación móvil real (primera etapa)

- El inicio de sesión ahora solicita credenciales a Supabase Auth, y consulta la identidad y el rol en la API FastAPI.
- La API valida el JWT y consulta la relación usuarios/clientes/roles con los permisos existentes.
- El rol administrador NO se obtiene del correo ni del formulario.
- El token se almacena en almacenamiento seguro del dispositivo.
- Se requiere compilar con `--dart-define=SUPABASE_URL=https://....supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=MODAPLUS_API_URL=https://...`.
- Las claves publicables no son secretos, pero las claves `service_role` jamás deben incorporarse a Flutter.
- El registro móvil queda temporalmente deshabilitado: la web requiere identificación, tipo de documento y otros datos para activar cuentas. No se debe crear una cuenta incompleta.
- Pendiente: renovar tokens automáticamente, restaurar sesiones tras reiniciar, recuperación real de contraseña, cierre de sesión integrado en todas las vistas, pedidos transaccionales y notificaciones.
- **No habilitar producción todavía.** La app conserva datos locales de demostración para pedidos e inventario.
- No se modificó el repositorio web.
