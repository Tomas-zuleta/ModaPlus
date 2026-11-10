# Integración segura con la base de datos existente

Se consultó **en modo lectura** el código público de MonsalveGod/ModaPlus para identificar tablas y esquema: `usuarios`, `usuarios_roles`, `roles`, `clientes`, `ventas`, `planes_separe` y `variantes_producto`.

## Entrega
- Autenticación de peticiones API mediante token Supabase validado por `/auth/v1/user`.
- Identidad resuelta en `usuarios.auth_user_id`; nunca confiar en `id_cliente` suministrado por la app.
- Consulta de compras y planes filtrada por cliente autenticado.
- Resumen administrativo y alertas de stock bajo con control de permisos.
- Uso de la clave publicable + JWT de usuario; sin secretos privilegiados ni escritura en producción.
- Pruebas unitarias de rechazo de tokens ausentes y roles sin permisos.

## Pendientes antes de producción
- Sustituir login simulado Flutter por Supabase Auth con almacenamiento seguro de sesión.
- Revisar las políticas RLS reales del proyecto y confirmar que los roles con permisos pueden consultar todas las tablas necesarias.
- Implementar operaciones de creación/aprobación de pedidos con transacciones atómicas y protección contra pedidos duplicados.
- Diseñar notificaciones push (FCM), consentimiento, token de dispositivo, límites de frecuencia y auditoría.
- Integrar resultados reales en las pantallas Flutter, comprobar esquemas de respuesta y pruebas end-to-end.
- El dashboard parcial no debe usarse para cifras contables oficiales.

El repositorio web **no fue modificado**.
