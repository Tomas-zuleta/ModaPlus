# Conexión Supabase: estado de esta entrega

- La aplicación usa Supabase Flutter y consulta las tablas reales de ventas y planes separe, bajo RLS.
- Mis compras muestra registros de `ventas` filtrados por el id de cliente autenticado.
- Mis planes muestra registros de `planes_separe` filtrados por el mismo cliente.
- El dashboard muestra los últimos 100 registros visibles al usuario. Las cifras son **parciales**, no equivalen a la contabilidad del negocio.
- Las alertas del dashboard se basan en pedidos pendientes de esos registros. Faltan las alertas de inventario real.
- Se ha bloqueado el checkout simulado: no se marca una compra como confirmada sin persistencia real.
- Los estilos base del modo oscuro usan azul marino #0F172A, tarjetas #1E293B, bordes #334155 y verde menta #6EE7A8. Algunas pantallas antiguas todavía usan colores fijos y requieren migración.
- **Pendiente:** consulta de catálogo/variantes y stock real, RPC transaccional de checkout y aprobación, planes con abonos detallados, actualización de perfil, gráficos completos, notificaciones y pruebas de integración.
- La aplicación requiere configurar `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` al compilar.
- **No se modificó el repositorio web ni la base de datos.**
