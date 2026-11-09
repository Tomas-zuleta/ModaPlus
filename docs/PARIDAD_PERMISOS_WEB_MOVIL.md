# Paridad de permisos entre ModaPlus web y móvil

El código web (`src/shared/utils/accessControl.ts`) reconoce el rol de superadministrador por id_rol=1 o por nombre normalizado, y evalúa los permisos por módulo y acción (`view`, `create`, `edit`, `delete`).

Se implementó `AdminPermissions` para consultar `usuarios`, `usuarios_roles`, `roles`, `roles_permisos`, `modulos` y `permisos` desde la sesión autenticada. Superadministradores activos tienen todas las acciones de interfaz, como en la web; los demás requieren permisos específicos. Se conectó al módulo de proveedores para lectura, creación, edición y desactivación.

**Seguridad:** la comprobación móvil no sustituye RLS, grants, ni validaciones de RPC en servidor. No se otorgan roles, no se modifican políticas ni se actualiza Supabase. No se implementa eliminación física de proveedores: requiere revisar relaciones y el flujo de la web.

**Paridad funcional pendiente:** inventario/productos, variantes, colores, tallas, categorías, compras, ventas, plan separe, devoluciones, cambios, pérdidas, clientes, usuarios y roles. Cada módulo debe integrar acciones con las mismas funciones transaccionales y reglas de negocio de la web; no hacer UPDATE/DELETE directo de movimientos contables.

**Pruebas pendientes:** flutter analyze/test, Android y matriz de roles con cuentas de prueba; no se ha probado RLS real.
