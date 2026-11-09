# Integración móvil y web

El único repositorio editable es Tomas-zuleta/ModaPlus. MonsalveGod/ModaPlus es de solo lectura.

La web usa Supabase Auth, PostgreSQL, RLS y RPC transaccionales. Entidades: productos, variantes_producto, categorias, colores, tallas, ventas, detalles_venta, planes_separe y abonos_separe.

El identificador de producto es id_producto y el de variante es id_variante. El inventario autoritativo está en variantes_producto.stock_actual.

No crear pedidos con SQL directo desde Flutter: se debe llamar una operación autorizada que valide precios, permisos y stock atómicamente. Nunca incluir service_role ni contraseñas de la web en la app.

## Estado

Implementado: base de API de lectura de catálogo y cliente HTTP Flutter desacoplado. Pendiente: autenticación, variantes, pedidos, separe, sincronización y pruebas de integración.
