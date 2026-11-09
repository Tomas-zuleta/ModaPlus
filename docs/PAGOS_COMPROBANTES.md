# Pagos móviles: transferencia, QR y comprobante

## Referencia existente (solo lectura)
El checkout de la web usa transferencia/QR, acepta comprobantes PNG/JPG/PDF de máximo 1 MB y los guarda en el bucket privado `comprobantes` con ruta `{auth.uid()}/venta/{uuid}-{nombre}`. La venta queda `PENDIENTE` hasta que el administrador verifica el comprobante.

## Implementado en móvil
- Paso de pago después del carrito con importe, QR HTTPS configurable y selector de archivos.
- Validación de extensión, tamaño y firma básica del archivo; previsualización para imágenes.
- Consentimiento explícito para adjuntar comprobante.
- El botón final no crea pedidos ni sube archivos todavía: muestra el bloqueo de seguridad claramente.
- QR configurable con `--dart-define=MODAPLUS_PAYMENT_QR_URL=https://...`; no se usa un QR de ejemplo que pueda desviar pagos.

## Requisitos para habilitar el envío real
1. Comprobar el RPC/flujo `saveSale` usado por la web y sus permisos RLS con usuario cliente.
2. Asociar el producto y variante del catálogo móvil a `id_variante` real; no usar IDs locales de demostración.
3. Validar importes y stock en PostgreSQL, de forma atómica, y generar una clave idempotente por intento.
4. Subir el comprobante a bucket privado `comprobantes`, ruta `auth.uid()/venta/uuid-nombre`, y limpiar archivos huérfanos ante errores.
5. Guardar venta y detalles como `PENDIENTE`; no marcar pagado hasta la revisión administrativa.
6. Mostrar estado, fecha y comprobante en Mis compras; permitir aprobar/rechazar solo a administradores autorizados.
7. Verificar políticas RLS y reglas Storage, escaneo de archivos y límites del servidor antes de activar producción.

**No se ha modificado el repositorio web ni su base de datos.**
