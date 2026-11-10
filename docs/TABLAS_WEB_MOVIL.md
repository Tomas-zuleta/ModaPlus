# Correspondencia de tablas entre ModaPlus web y móvil

Fuente: `src/shared/services/modaPlusBackend.ts` y `src/types.ts` del repositorio web (consultado en modo lectura).

Tablas presentes en el snapshot administrativo web:

- `variantes_producto`: Variantes e inventario
- `productos`: Productos
- `fotos_producto`: Fotografías
- `clientes`: Clientes
- `ventas`: Ventas
- `detalles_venta`: Detalle de ventas
- `compras`: Compras
- `detalles_compra`: Detalle de compras
- `proveedores`: Proveedores
- `planes_separe`: Planes Separe
- `detalles_plan_separe`: Detalle de planes
- `abonos_separe`: Abonos
- `devoluciones`: Devoluciones
- `detalles_devolucion`: Detalle de devoluciones
- `cambios`: Cambios
- `detalles_cambio`: Detalle de cambios
- `perdidas`: Pérdidas
- `colores`: Colores
- `tallas`: Tallas
- `categorias`: Categorías
- `roles`: Roles
- `roles_permisos`: Permisos de roles
- `modulos`: Módulos
- `permisos`: Permisos
- `usuarios`: Usuarios
- `usuarios_roles`: Roles de usuarios

## Implementación móvil

La sección **TABLAS** del panel administrativo consulta cada tabla usando `select('*')`, por lo que los nombres y campos se toman del esquema real al momento de la consulta, sin inventar columnas. Muestra como máximo 30 filas por página, y permite avanzar a la siguiente página. Oculta campos sensibles y no implementa escrituras.

**Importante:** el listado no demuestra que un rol tenga permiso de lectura sobre todas las tablas; las políticas RLS del servidor pueden devolver datos parciales o denegar acceso. El snapshot web tampoco es una descripción completa del esquema PostgreSQL: podrían existir otras tablas o columnas no utilizadas por la web.

Para habilitar formularios de creación/edición por módulo, verificar primero los campos obligatorios, claves foráneas, reglas RLS y procedimientos RPC correspondientes. No habilitar mutaciones genéricas de tablas, ni modificaciones directas del stock o estados de pago.

No se modificó la base de datos ni el repositorio web.
