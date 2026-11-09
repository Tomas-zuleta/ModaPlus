# Rediseño Flutter — identidad visual ModaPlus

Se tomó como referencia únicamente de lectura el estilo del repositorio web: fondo #F8FAFC, tinta #1E293B, verde #3D8B66 y acento menta #6EE7A8.

- Pantalla de autenticación editorial con título grande, detalles gráficos y tarjetas redondeadas.
- Botones con animación de presión, carga y flecha.
- Campos con foco visible y accesibilidad para mostrar contraseña.
- Transiciones entre login y registro sin cambios en el proyecto web.

## Seguridad y límites

La autenticación Flutter continúa siendo una **demo local** y no debe usarse en producción. Se eliminó la asignación de permisos de administrador por prefijo de correo en la pantalla de acceso; el siguiente paso obligatorio es implementar Supabase Auth real y verificar roles en servidor. No se han probado compilaciones Flutter en un dispositivo.
