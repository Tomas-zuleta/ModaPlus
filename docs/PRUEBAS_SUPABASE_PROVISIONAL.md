# Paso 2: configurar la base provisional (NO DESPLEGADO)

**Exclusivamente para el proyecto de desarrollo `prubasmoda`.**

1. Confirmar que el proyecto tiene 23 tablas en `public` y que no es el proyecto original.
2. Abrir Supabase SQL Editor, pegar el contenido de `supabase/staging/02_lectura_y_datos_demo.sql` y ejecutar.
3. La consulta final debe devolver `tablas_publicas=23`, `productos_demo=1` y `roles_demo=2`.
4. No se asigna ningún rol a cuentas de Auth. Una cuenta de prueba debe crearse y vincularse expresamente en una etapa posterior. No enviar contraseñas ni secretos por chat.

## Alcance y límites
- 23 políticas RLS de **solo lectura** para usuarios autenticados que tengan un rol activo SUPERADMIN o ADMINISTRADOR. Los demás usuarios no pueden leer esas tablas.
- Los registros son ficticios; no se copia información real.
- Las políticas **no** habilitan INSERT, UPDATE o DELETE desde Flutter. La aplicación no puede todavía registrar compras, ventas ni devoluciones contra esta base.
- El código de producción y la base original no se modifican.
- La estructura provisional puede no coincidir con los procedimientos de la web. Antes de habilitar operaciones monetarias se necesita revisar los RPC originales.
- No se ejecutó el SQL de forma remota; solo se preparó para revisión y ejecución manual.
