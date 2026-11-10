# Integración transaccional — interfaz administrativa avanzada

Se conectaron los botones **Registrar** de Compras, Ventas, Plan Separe y Devoluciones a los adaptadores RPC de la web (`guardar_compra`, `guardar_venta`, `guardar_plan_separe`, `guardar_devolucion`). Los botones se muestran solo con permiso de creación. La pantalla solicita cabecera y detalles JSON, valida su forma y exige confirmación antes de ejecutar. **No es aún el formulario de negocio completo de la web** y los ejemplos requieren sustituirse por datos válidos; no hay ejecución automática.

La operación se realiza en el Supabase configurado en la app. Para evitar mutaciones accidentales, la plantilla contiene campos nulos y detalles vacíos, por lo que no permite guardar sin introducir datos. Las reglas definitivas, restricciones, autorizaciones e inventario deben aplicarse en los RPC del servidor.

No se han desplegado nuevas funciones ni migraciones. No están automatizados los correos de rechazo, inicio de sesión, cambio de estado o aprobación pos-transacción. Falta validar la matriz RLS, los contratos completos de cada RPC y las pruebas Flutter/Android antes de usar en producción.
