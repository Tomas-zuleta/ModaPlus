# Paso 07 — Otros RPC para la base de pruebas

Solo `prubasmoda`. **Ejecutar DESPUÉS de 05 y 06** en SQL Editor.

- `guardar_devolucion`: crea una **solicitud PENDIENTE** si la venta está aprobada, hay unidades suficientes y la fecha de compra no supera 14 días. **No reintegra dinero ni stock**.
- `gestionar_perdida`: crea pérdidas, permite anular (reponer existencias) y eliminar únicamente después de anular.
- `actualizar_roles_usuario`: asigna roles, protege el Superadmin.
- `rechazar_venta_online`: registra el rechazo con motivo de una venta online pendiente.

Todas estas operaciones comprueban que el JWT pertenece a un administrador activo y son transacciones SQL atómicas. No se concede escritura directa sobre tablas financieras.

## Lo que todavía NO cubre
No implementa creación de cuentas Auth desde el móvil, aprobaciones de pedidos online ni flujo de cambio por otro producto. La devolución se registra como solicitud y su aprobación/reembolso sigue pendiente de contrato SQL definitivo. No existe validación integral contra la BD original. Aplicar solo en proyecto de desarrollo ficticio.

Este SQL no se ha ejecutado remotamente.
