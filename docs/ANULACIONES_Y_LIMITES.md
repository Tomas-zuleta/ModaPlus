# Anulaciones y límites operativos

Implementado en Flutter: botón de anulación para compras, planes separe, abonos y pérdidas, sujeto al permiso `annul`, confirmación y respuesta del servidor.

Contratos cotejados con la web:
- Compra: `guardar_compra` con `estado=ANULADA` y detalles actuales, sin edición ordinaria.
- Plan: `anular_plan_separe(p_id)`.
- Abono: `anular_abono(p_id)`.
- Pérdida: `gestionar_perdida(p_accion='anular',p_perdida)`.
- Devoluciones: la web **no ofrece anulación de devoluciones aprobadas**. Se conserva la prohibición; no se añadió una mutación que el backend no respalda.

Pendiente de verificar en integración: nombre real de la tabla de detalles de compra, esquema RPC de compra anulada, RLS, estados y stock; **no usar la anulación de compra en producción hasta verificar**.

Los correos automáticos de inicio de sesión, aprobación, rechazo y cambios de estado requieren una solución del lado del servidor, permisos de despliegue y pruebas de entrega. No se implementaron ni desplegaron en este commit.

Usuarios, roles e inventario siguen requiriendo formularios completos. Las pruebas Flutter/Android y la equivalencia total no están confirmadas.
