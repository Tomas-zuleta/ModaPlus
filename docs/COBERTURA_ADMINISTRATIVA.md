# Cobertura administrativa móvil — estado verificable

Se incorporaron vistas de lectura con control de permisos para productos, variantes, tallas, compras, clientes, usuarios, roles, ventas, Plan Separe, abonos, devoluciones, cambios y pérdidas. Cada pantalla consulta una tabla de negocio y muestra campos definidos, sin edición indiscriminada de movimientos.

**CRUD existente:** Proveedores (crear, consultar, editar, desactivar); Categorías y Colores (crear, consultar, editar, eliminar). **NO están completos** los CRUD de los demás módulos: sus pantallas nuevas son solo lectura. La paridad funcional exige portar las funciones transaccionales, validaciones y formularios de la web, verificar políticas RLS y ejecutar pruebas.

No se modificaron funciones del servidor, web, permisos de producción ni base de datos. No se ejecutaron Flutter analyze/test/Android desde este entorno.
