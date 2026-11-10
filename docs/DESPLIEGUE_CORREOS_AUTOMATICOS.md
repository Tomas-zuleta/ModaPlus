# Correos automáticos: propuesta de despliegue (NO DESPLEGADA)

## Archivos
- `supabase/migrations/20261109210000_modaplus_email_outbox.sql`: captura transiciones de estado de ventas a `APROBADA` o `RECHAZADA` en una cola transaccional y crea RPC de reclamación para `service_role`.
- `supabase/functions/process-sale-emails/index.ts`: trabajador autenticado por secreto de servidor que entrega correos mediante Resend, con reintentos e idempotencia.

## Configuración necesaria antes de probar en staging
1. Crear un proyecto de staging con la estructura de `ventas`, `clientes` y las relaciones correspondientes. Revisar SQL, políticas, restricciones y permisos con un DBA. Ejecutar la migración SOLO tras aprobarla.
2. Verificar un dominio remitente en Resend. Configurar secretos `RESEND_API_KEY`, `MODAPLUS_EMAIL_FROM` (p.ej. `ModaPlus <pedidos@dominio-verificado>`), `MODAPLUS_EMAIL_WORKER_SECRET` (aleatorio fuerte), `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`. Nunca incluirlos en Flutter.
3. Desplegar la Edge Function `process-sale-emails` con autenticación JWT deshabilitada **solo para esta función**: autentica cada petición con el secreto `x-modaplus-worker-secret`. No exponer ese secreto a aplicaciones cliente.
4. Programar desde un scheduler seguro una llamada POST periódica (p.ej. cada minuto) a la función, incluyendo el secreto en cabecera. Sin scheduler, los correos NO salen automáticamente.
5. Pruebas staging: ventas aprobadas/rechazadas por web y móvil, reintentos, ausencia de destinatario, errores de Resend, cambios de estado repetidos, permisos RLS y concurrencia. Verificar que no haya correos duplicados. La idempotencia del proveedor reduce duplicados pero no sustituye pruebas.
6. Después de las pruebas, solicitar aprobación expresa para cualquier despliegue a producción.

## Limitaciones
- El código **no** está desplegado ni probado contra el esquema SQL real.
- No hay envío de correos de inicio de sesión ni de cada estado de pedido; la cola cubre solamente APROBADA y RECHAZADA. El correo de registro existente sigue siendo independiente.
- La creación de cuentas administrativas, matriz granular de permisos y paridad completa de inventario requieren más trabajo.
- Las reglas de devolución, pérdidas y retención de abonos requieren verificación legal y transaccional antes de habilitarse en producción.
