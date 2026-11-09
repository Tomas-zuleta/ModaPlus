# Paridad administrativa — entrega incremental

Se añadió una entrada GESTIÓN en navegación administrativa con Proveedores, Categorías y Colores. Las categorías y colores usan las mismas tablas y columnas que la web y validan permisos de módulo y acción antes de consultar, crear, editar o eliminar. Las restricciones y RLS de Supabase siguen siendo la autoridad final.

No se ha habilitado CRUD indiscriminado de ventas, compras, inventario, devoluciones, roles o planes separe. Esos módulos necesitan reutilizar sus RPCs y flujos transaccionales web. No se han modificado datos reales ni desplegado migraciones. Pendiente flutter analyze, flutter test, Android y pruebas RLS con roles de ensayo.
