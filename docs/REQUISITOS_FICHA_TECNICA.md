# Implementación orientada por ficha técnica aprobada

Fuente: Ficha Moda Plus - Aprobada_Sept 02 (1).pdf, págs. 5–8.

## Alcance web
- Roles y usuarios: CRUD de configuración, estados, asignaciones.
- Catálogo: categorías, productos, colores, variantes y control de existencias.
- Compras: registrar, consultar y anular; devoluciones parciales o totales.
- Ventas: registrar y consultar; pedidos con cambios de estado.
- Plan Separe: registrar, consultar, anular y gestionar abonos.
- Devoluciones: registrar y consultar; indicadores administrativos.

## Alcance móvil
La ficha indica acceso de administrador a las funcionalidades aplicables y catálogo/carrito/pedidos para clientes. Se mantiene segregación por permisos del servidor.

## Reglas identificadas
- Cuota inicial mínima de $20.000 COP por prenda, hasta dos meses.
- Pedidos: reglas de vencimiento semanal y manejo de saldos parciales.
- Inventario: compras suman, ventas descuentan; usar RPC transaccionales.
- Devoluciones: plazo de dos semanas según ficha, sujeto a derechos legales.
- La retención de abonos y saldos a favor requiere revisión jurídica previa a cualquier automatización.

## Dirección
La ficha indica «Parque principal de San Cristóbal» como referencia. No confirma calle, número ni horarios. Se reemplazó la dirección ficticia de Medellín por la referencia documentada.

## Correos
Se verificó que la función web `send-order-approved` recibe `saleId`, igual que la invocación Flutter. La función web `send-account-registered` usa la sesión autenticada. **No se verificó el despliegue ni la entrega real de correos**. Faltan avisos de inicio de sesión, rechazo y cambios de estado; deben enviarse desde el servidor después de operaciones confirmadas, con autorización e idempotencia.

## Pendientes
No se completó CRUD transaccional en todos los módulos, no se modificó el backend web ni producción y no se ejecutaron pruebas Flutter/Android. Este documento no afirma paridad funcional completa.
