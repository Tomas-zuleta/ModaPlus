# Integración de correo y contenido demostrativo (móvil)

## Reutilización de funciones web
La app invoca `send-account-registered` después de activar un cliente autenticado, de manera no bloqueante para el registro. Si el usuario confirma su correo, se reintenta al completar su perfil en el primer inicio de sesión. La función debe estar desplegada y configurada con Resend en Supabase.

La pantalla de revisión administrativa incorpora la acción **Enviar confirmación por correo** solo cuando la venta ya figura `APROBADA`. Invoca `send-order-approved`, que valida sesión, permisos y estado en el servidor. No habilita la aprobación ni envía avisos de cambio de estado no soportados.

**Pendiente:** correo por inicio de sesión, rechazo y cualquier transición de estado: necesitan funciones/eventos seguros del servidor, autorización, rate limiting e idempotencia. La invocación desde la app no garantiza entrega y podría duplicar envíos si web y móvil lo hacen en paralelo; verificar comportamiento del proveedor.

## Ubicación y términos
La ubicación visible es una **referencia de ejemplo** al centro de Medellín; NO es la dirección del comercio. El texto legal se muestra dentro de la app y está etiquetado DEMO; no es una política aprobada ni sustituye el documento final. La casilla de lectura no guarda consentimiento versionado en Supabase. Antes de producción, completar datos del comerciante, aprobación legal, política de datos y registro de consentimiento con versión y fecha.

No se modificó web, funciones desplegadas ni base de datos.
