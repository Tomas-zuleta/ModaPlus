# ModaPlus móvil: Supabase directo, sin FastAPI

**Alcance:** únicamente el repositorio móvil. No se ha escrito en el repositorio web ni en su base de datos.

## Configuración
La app usa el mismo proyecto Supabase que la web, pero necesita parámetros públicos proporcionados al compilar:

```powershell
flutter pub get
flutter run -d 23129RA5FL --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
```

Nunca usar `service_role` en el teléfono. La URL y clave publicable deben obtenerse de Supabase Project Settings → API Keys. No están incluidas en el repositorio.

## Implementado
- Supabase Flutter inicializa Auth y almacenamiento de sesión.
- Inicio de sesión real con contraseña y resolución de cuenta y rol desde `usuarios`, `clientes`, `usuarios_roles`, `roles`.
- Solicitud real de correo para recuperación de contraseña, sin código ficticio.
- Consultas de solo lectura para pedidos y planes propios, y ventas recientes para administrador.
- Se retiró el directorio FastAPI, su despliegue y sus pruebas del repositorio móvil.

## Pendiente y límites
- La interfaz de pedidos, planes, dashboard y carrito todavía usa AppStore local de demostración. Los métodos Supabase nuevos **aún no están conectados a esas pantallas**.
- El formulario de registro móvil no está conectado; crear cuenta desde la web.
- La recuperación de contraseña requiere configurar el redirect/deep link de vuelta a la app o completar el flujo mediante la web.
- Las escrituras de pedidos y cambios de estado necesitan RPCs transaccionales existentes, o aprobación para crear funciones nuevas en Supabase. No se deben realizar escrituras directas inseguras desde Flutter.
- Verificar RLS y permisos con cuentas reales en un entorno de prueba antes de habilitar compras.
- La app no envía notificaciones push todavía.
- No se han ejecutado pruebas de integración con la base de datos real.
