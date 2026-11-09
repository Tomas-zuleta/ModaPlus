# Módulo móvil de proveedores

Se implementa un módulo administrativo específico para `proveedores`, conforme a `saveSupplier` en el servicio de ModaPlus web: `id_proveedor`, `nit`, `razon_social`, `contacto`, `telefono`, `correo`, `direccion`, `estado`.

La aplicación consulta hasta 300 proveedores, filtra por estado y permite crear, editar o desactivar con confirmación. La desactivación evita borrar historial de compras. **No se implementa eliminación física** hasta comprobar las relaciones y permisos.

Todas las escrituras se ejecutan con el JWT de la sesión mediante el SDK Supabase y deben ser autorizadas por RLS. **La visibilidad de la navegación no es autorización.** Antes de usar con datos reales, probar que un cliente normal no puede leer ni modificar proveedores, y que el rol administrativo correcto sí puede.

No se modifica la base de datos ni el repositorio web. Falta verificar análisis, pruebas Flutter y ejecución Android.
