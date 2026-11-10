# Entrega: microinteracciones, lógica y comunicación con backend

## Mejoras visuales
- Tarjetas de producto con animación de presión y esquinas redondeadas.
- Barra inferior con transiciones de escala, color y tipografía.
- Selector de cantidad con transiciones y controles accesibles.

## Correcciones de lógica
- No se aceptan cantidades negativas, superiores al inventario de demostración ni artículos sin existencias.
- El carrito se limpia al iniciar una nueva sesión, evitando mezclar compras de distintos usuarios.
- Se validan transiciones de estado de pedidos y límites de abonos.
- No se permite solicitar pedidos sin sesión o con carrito vacío.
- Se impide pulsar repetidamente el botón de solicitar pedido.

## Backend
- El cliente HTTP ahora valida la URL, aplica timeout y ofrece una comprobación de salud del servidor.
- El endpoint de catálogo sigue disponible para integrar los datos reales.

## Límites y seguridad
- El catálogo visible, el inventario y los pedidos aún utilizan datos locales de demostración.
- La solicitud de pedido **NO se envía a producción** y no debe considerarse una compra real.
- El login continúa siendo de demostración: antes de publicar se requiere autenticación real.
- No se modificó el repositorio de la web.
- Esta entrega necesita validación mediante GitHub Actions y pruebas en dispositivo.
