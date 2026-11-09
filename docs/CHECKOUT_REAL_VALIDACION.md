# Checkout real preparado, activación controlada

La aplicación móvil reutiliza el mismo RPC `guardar_venta` y bucket privado `comprobantes` que la web. El servicio valida sesión, cliente activo, variantes, precio y stock antes de subir el comprobante y llamar al RPC con `estado=PENDIENTE`, `origen=TIENDA_ONLINE` y detalles reales. El servidor debe volver a validar TODO: los controles del teléfono no son autoridad.

La opción está **desactivada por defecto**. Solo habilitar en entorno de pruebas, después de revisar RLS, privilegios SQL, atomicidad, descuento de stock e idempotencia:

```
flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=MODAPLUS_PAYMENT_QR_URL=https://... --dart-define=ENABLE_REAL_CHECKOUT=true
```

El flujo existente de la web no expone una clave de idempotencia para `guardar_venta`. Ante timeout o respuesta ambigua **no reintentar sin consultar Mis compras**: podría duplicarse una venta. Los errores SQL explícitos intentan limpiar el comprobante; los errores ambiguos no borran el archivo para evitar perder evidencia. La aprobación administrativa y notificaciones push no están implementadas aquí.

No se hicieron escrituras a Supabase ni cambios al repositorio web. Esta entrega no fue probada en dispositivo ni en la base real.
