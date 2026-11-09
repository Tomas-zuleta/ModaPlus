# Integración del panel y operaciones de ventas

## Hecho
- El dashboard móvil consulta `ventas`, `variantes_producto` y `planes_separe` en Supabase con la sesión autenticada.
- Muestra cifras parciales, alertas de pedidos pendientes, stock bajo y barras mensuales de ventas aprobadas.
- Se suscribe a eventos Realtime de `ventas` cuando la publicación de Supabase y RLS lo permitan; la actualización manual sigue disponible.
- No se han creado funciones, tablas, políticas ni escrituras en la base compartida.
- Se inspeccionó el repositorio web **solo lectura** y se identificaron RPC existentes: `guardar_venta`, `rechazar_venta_online`, `reenviar_comprobante_venta_online`, `expirar_pedidos_tienda`. La web almacena archivos en el bucket privado `comprobantes`.

## Bloqueos de producción
- El carrito móvil utiliza productos de demostración con identificadores locales; **no se deben enviar como `id_variante` real**.
- Antes de habilitar `guardar_venta` hay que consumir el catálogo de variantes reales, validar importes y cantidades en la función SQL, comprobar permisos RLS y la atomicidad del inventario.
- El RPC existente puede no ser idempotente: evitar reintentos automáticos hasta verificarlo.
- La aprobación administrativa debe usar únicamente funciones existentes verificadas y con autorización del servidor; no hacer `update` directo desde Flutter.
- Las notificaciones push requieren infraestructura y consentimiento; Realtime solo actualiza la pantalla abierta, no equivale a push.
- Las cifras del dashboard no representan totales oficiales mientras exista paginación parcial.
- El modo oscuro aún tiene pantallas con colores fijos pendientes de adaptar.

**No se ha modificado el repositorio web ni su base de datos.**
