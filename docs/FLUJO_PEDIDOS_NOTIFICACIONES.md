# Diseño de pedidos, dashboard y notificaciones

## Implementado en esta entrega
- Dashboard administrativo de demostración con tarjetas de ventas, inventario, pedidos pendientes y planes separe.
- Gráfica de ventas de los últimos seis meses, calculada a partir de pedidos locales pagados/entregados.
- Alertas de pedidos pendientes y existencias bajas, basadas en los datos locales de ejemplo.
- Corrección del cambio de estado: se valida la transición ANTES de mutar el pedido.

## Aún no conectado a producción
- El login actual es simulado y NO permite iniciar como administrador de forma segura.
- Los pedidos y las ventas se guardan solo en memoria; no llegan a la web ni a Supabase.
- El inventario del catálogo es de demostración y no se descuenta al aprobar pedidos.
- No existen notificaciones push, tareas programadas ni actualizaciones en tiempo real.

## Siguiente fase: integración real
1. Confirmar tablas, relaciones, políticas RLS y roles existentes en la base de datos de la web (solo lectura).
2. Configurar Supabase Auth, verificar tokens en FastAPI y resolver roles desde el servidor.
3. Crear endpoint transaccional para pedidos con precios e inventario validados en PostgreSQL; no confiar en importes enviados por Flutter.
4. Definir estados: pendiente de revisión, aprobado, rechazado, preparado, entregado. Mantener historial de auditoría.
5. Crear endpoints de métricas, alertas y listado de pedidos con permisos de administrador.
6. Registrar tokens de dispositivos y enviar notificaciones mediante Firebase Cloud Messaging, respetando consentimiento y preferencias.
7. Enviar avisos de carritos abandonados o perfil incompleto solo con autorización, límites de frecuencia y posibilidad de desactivarlos.
8. Probar en un entorno separado antes de conectar la base de datos de producción.

**El repositorio web permanece sin modificaciones.**
