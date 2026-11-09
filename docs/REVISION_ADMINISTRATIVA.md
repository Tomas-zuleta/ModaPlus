# Revisión administrativa de ventas

Desde Pedidos, clientes y administradores pueden abrir una venta y consultar sus datos. La pantalla solicita una URL firmada temporal (120 segundos) para el comprobante del bucket privado `comprobantes`, sin hacer públicos los archivos. La autorización efectiva depende de RLS y las políticas de Storage.

**No hay aprobación/rechazo desde la app todavía.** No es seguro escribir directamente `ventas.estado`: la aprobación debe invocar una operación SQL transaccional existente, con validación de rol, estado previo, precio, reserva y descuento de inventario. Tampoco se implementaron notificaciones push ni integración FCM. El dashboard ya ofrece avisos dentro de la aplicación y consulta cambios de ventas por Realtime cuando está habilitado.

Los informes del dashboard usan subconjuntos de hasta 500 registros y no sustituyen reportes paginados o agregaciones SQL.

No se modificó el repositorio web ni la base de datos. Ejecutar `flutter analyze` y `flutter test` antes de integrar.
