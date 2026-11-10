# INSTALACIÓN EN UN SOLO PASO (STAGING)

Este archivo combina los pasos 05, 06 y 07, que aún **no han sido desplegados**. Úsalo exclusivamente en el proyecto Supabase **prubasmoda** que ya tiene 23 tablas, el producto `DEMO-001` y tu cuenta SUPERADMIN.

1. Desde GitHub abre `supabase/staging/INSTALAR_05_06_07_en_prubasmoda.sql`, pulsa **Raw** y copia todo el contenido.
2. Supabase → `prubasmoda` → SQL Editor → New query. Verifica el nombre del proyecto antes de continuar.
3. Pega el SQL y ejecuta **Run**. El resultado final debería indicar **10 RPC**, **8 políticas CRUD**, **1 producto DEMO**.
4. Si aparece un error, **no ejecutes de nuevo a ciegas**. Copia el texto del error y su línea; no compartas contraseñas ni claves secretas.
5. En Visual Studio Code ejecuta `git pull origin feature/mobile-api-foundation` y la aplicación con los `--dart-define` de `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` de prubasmoda. Luego prueba: Gestión > Compras > Crear nuevo (primero 5 unidades); Pedidos > Nueva venta (1 unidad); Separes > Crear un Plan Separe > Registrar abono (desde abajo).
6. Verifica también que los registros siguen allí luego de cerrar y abrir la app. No hagas pruebas con información de clientes reales.

**Limitaciones:** funciones y validaciones de staging, no de producción; falta una matriz completa de permisos, creación/gestión de usuarios Auth, cambio por otra prenda, aprobación de venta online y correo realmente desplegado. Las devoluciones se guardan como solicitudes pendientes, sin reembolso. La anulación de Plan Separe usa una simulación de la regla de 50% pendiente de revisión legal. Sin pruebas SQL contra el proyecto real, no afirmar paridad con la web.
