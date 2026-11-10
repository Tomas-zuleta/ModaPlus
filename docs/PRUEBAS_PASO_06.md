# Paso 06 — Guardar ventas, compras, Plan Separe y abonos

**STAGING ÚNICAMENTE: prubasmoda. No desplegar en producción.**

Ejecutar `supabase/staging/06_transacciones_demo.sql` manualmente en SQL Editor **después** del paso 05. El script verifica que la estructura provisional incluya `DEMO-001` y rol `SUPERADMIN`.

Incluye funciones `guardar_compra`, `guardar_venta`, `guardar_plan_separe`, `registrar_abono_separe`, `anular_abono`, `anular_plan_separe`. Stock y saldos se validan en transacciones SQL con bloqueos y permisos del administrador; las tablas financieras no obtienen permisos de escritura directa.

## Recorrido de prueba manual en Android
1. Iniciar sesión como administrador ficticio y abrir Gestión > Compras a proveedores.
2. Crear una compra para la variante DEMO-001, por ejemplo 5 unidades, y comprobar que aumente el stock. Registrar una compra **antes** de intentar vender, porque el stock ficticio inicia en 0.
3. En Pedidos, elegir Nueva venta. Seleccionar el cliente ficticio y la variante, cantidad 1. Confirmar y verificar en el historial y el inventario.
4. En Separes, crear un plan con 1 unidad y abono inicial de COP 20.000 (si el precio total es COP 45.000). Abrir Registrar abono desde abajo y abonar, por ejemplo, COP 5.000. Comprobar el nuevo saldo.
5. No ejecutar anulaciones financieras hasta revisar el tratamiento contable del umbral de 50%.

## LIMITACIONES DE ESTE BACKEND PROVISIONAL
- No replica de forma certificada los procedimientos de producción; no usar sus funciones en producción.
- No incluye la aprobación online ni el comprobante de transferencias.
- El criterio de liquidación del 50% procede de la ficha del proyecto y es **solo de simulación**, pendiente de evaluación legal. No enviar a clientes reales.
- No prueba por sí mismo RLS con JWT; eso se debe comprobar desde el Android.
- No se ejecutó ni desplegó desde este chat.
