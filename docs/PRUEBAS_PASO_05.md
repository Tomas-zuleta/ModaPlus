# Paso 05 — Datos maestros del staging (no desplegado)

Solo para `prubasmoda`. No ejecutar en producción.

**Motivo del fallo de guardado:** los 23 objetos iniciales solo tenían políticas SELECT para administradores; las peticiones INSERT/UPDATE/DELETE de Flutter se rechazan con RLS, y varios campos de formularios no existían.

Este script agrega columnas previstas por los formularios y políticas de CRUD en categorias, tallas, colores, proveedores, clientes, roles, productos y variantes. **Stock actual permanece protegido** por trigger: solo se puede cambiar mediante los RPC transaccionales de la siguiente etapa. No se autorizan escrituras directas a compras/ventas/abonos/devoluciones ni a usuarios.

En SQL Editor de `prubasmoda` ejecutar `supabase/staging/05_datos_maestros_demo.sql` con una nueva consulta. Requiere demo `DEMO-001` y rol `SUPERADMIN`. Comprobar que devuelve `politicas_crud=8`, `campo_proveedor=1`, `campo_cliente=1`.

No ejecutado en Supabase por el asistente; GitHub CI únicamente revisa Flutter, no este SQL. Datos de staging ficticios, no compatibles garantizados con producción.
