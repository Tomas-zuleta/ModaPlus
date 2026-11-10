# Correos, ubicación y documentos legales — pendientes de puesta en producción

## Inventario de servicios web (solo lectura)
- `supabase/functions/send-account-registered/index.ts`: requiere JWT y servicio Resend configurado; disponible para usuarios autenticados.
- `supabase/functions/send-order-approved/index.ts`: verifica permisos sobre ventas y que la venta esté APROBADA; utiliza idempotencia de envío.
- `docs/legal/terminos_y_condiciones.md`: BORRADOR, con placeholders de razón social, NIT, dirección, contacto y horario y advertencias de revisión legal.
- Footer web: Medellín, Colombia; no dirección física exacta verificada.

## Decisiones de seguridad
- No enviar correos desde Flutter usando claves de Resend o service_role.
- No enviar correo de aprobación hasta confirmar transición real del pedido; preferir evento confiable en servidor y outbox idempotente.
- Para avisos de inicio de sesión, emitir evento autenticado del lado servidor con protección anti-abuso, sin datos sensibles ni contraseña.
- Para registro, verificar la cuenta antes de enviar bienvenida, y no duplicar envíos entre web y móvil.
- Para cambios de estado, enviar únicamente después de transacción confirmada; incluir identificador y estado, no comprobantes privados.
- No modificar el proyecto web ni desplegar funciones en producción sin autorización.
- Registrar consentimiento legal en backend con versión, fecha y usuario una vez aprobado el texto; el checkbox local no constituye por sí solo una evidencia persistente.
- No inventar dirección, coordenadas, teléfono ni horarios. Configurar mapa y contacto cuando se confirmen los datos.

## Estado móvil
Se añadió acceso al borrador legal en Configuración y registro, checkbox obligatorio de lectura y una ficha informativa del local sin datos ficticios. Esto NO implementa envíos automáticos ni consentimiento persistente. Antes de habilitar registros reales, aprobar texto legal y almacenar consentimiento versionado.
