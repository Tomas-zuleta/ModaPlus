# Cambios administrativos y correo — estado de implementación

- Nuevos formularios de **tallas y clientes**: consultar, crear, editar y cambiar estado, usando permisos por módulo y RLS. No se eliminan físicamente clientes, por sus relaciones con ventas y saldos.
- Adaptadores Flutter de RPC existentes en la web: `guardar_compra`, `guardar_venta`, `guardar_plan_separe`, `guardar_devolucion` y `actualizar_roles_usuario`. Los adaptadores **no tienen aún formularios transaccionales completos ni son invocados por botones**. Se mantienen separados para evitar cambios incompletos en inventario.
- La web sigue siendo solo lectura y no se modificó Supabase producción.
- Correos: `send-order-approved` espera `saleId`, como envía Flutter. Aún faltan triggers/outbox para enviar avisos de rechazo, cambios de estado y aprobación después de confirmar la transacción, además del aviso de inicio de sesión. No afirmar que estos correos se envían automáticamente.
- Dirección y reglas de la ficha aprobada siguen visibles en Configuración.
- Pendientes pruebas `flutter analyze`, `flutter test`, Android, RLS y pruebas de RPC con datos de ensayo.
