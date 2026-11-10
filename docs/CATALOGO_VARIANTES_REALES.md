# Catálogo móvil real y relación con inventario

Se sustituyó el catálogo de demostración de la pestaña **Catálogo** por lecturas de las tablas `productos`, `variantes_producto`, `tallas`, `colores` y `categorias` de Supabase. No se usan datos falsos como fallback ante errores.

Cada tarjeta representa una variante real con `id_variante` explícito, precio, talla, color y stock de la base de datos. Se excluyen variantes inactivas, sin stock o con precio no positivo.

Los carritos conservan la referencia `variantId`; el paso de pago identifica y bloquea productos de demostración. Las otras vistas (Explorar/Favoritos) todavía pueden presentar contenido local, y requieren migración.

**Importante:** el precio y stock de Flutter son solo visuales. El RPC SQL `guardar_venta` debe validar stock/precio y gestionar la transacción; no se habilita el pago real hasta comprobarlo con pruebas. Las imágenes `imagen_url` se conservan en el modelo; el widget actual puede requerir adaptación para mostrarlas.

El catálogo usa límite de 1000 registros por tabla: no es todavía paginación exhaustiva. No se modificó el repositorio web ni la base compartida.
