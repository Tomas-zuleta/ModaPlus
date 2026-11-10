/// Tablas utilizadas por el snapshot administrativo de ModaPlus web.
/// El esquema de columnas se descubre mediante respuestas autorizadas de Supabase.
/// Las políticas RLS del servidor determinan qué registros puede leer el usuario.
class AdminTableDefinition {
  final String name;
  final String label;
  const AdminTableDefinition(this.name, this.label);
}

const adminTables = <AdminTableDefinition>[
  AdminTableDefinition('variantes_producto', 'Variantes e inventario'),
  AdminTableDefinition('productos', 'Productos'),
  AdminTableDefinition('fotos_producto', 'Fotografías'),
  AdminTableDefinition('clientes', 'Clientes'),
  AdminTableDefinition('ventas', 'Ventas'),
  AdminTableDefinition('detalles_venta', 'Detalle de ventas'),
  AdminTableDefinition('compras', 'Compras'),
  AdminTableDefinition('detalles_compra', 'Detalle de compras'),
  AdminTableDefinition('proveedores', 'Proveedores'),
  AdminTableDefinition('planes_separe', 'Planes Separe'),
  AdminTableDefinition('detalles_plan_separe', 'Detalle de planes'),
  AdminTableDefinition('abonos_separe', 'Abonos'),
  AdminTableDefinition('devoluciones', 'Devoluciones'),
  AdminTableDefinition('detalles_devolucion', 'Detalle de devoluciones'),
  AdminTableDefinition('cambios', 'Cambios'),
  AdminTableDefinition('detalles_cambio', 'Detalle de cambios'),
  AdminTableDefinition('perdidas', 'Pérdidas'),
  AdminTableDefinition('colores', 'Colores'),
  AdminTableDefinition('tallas', 'Tallas'),
  AdminTableDefinition('categorias', 'Categorías'),
  AdminTableDefinition('roles', 'Roles'),
  AdminTableDefinition('roles_permisos', 'Permisos de roles'),
  AdminTableDefinition('modulos', 'Módulos'),
  AdminTableDefinition('permisos', 'Permisos'),
  AdminTableDefinition('usuarios', 'Usuarios'),
  AdminTableDefinition('usuarios_roles', 'Roles de usuarios'),
];
