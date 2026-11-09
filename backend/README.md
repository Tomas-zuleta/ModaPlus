# ModaPlus Mobile API

Backend FastAPI independiente del repositorio web.

## Configuración

1. Crear un entorno Python e instalar `pip install -r requirements.txt`.
2. Copiar `.env.example` a `.env` (no subir credenciales).
3. Configurar `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` como variables de entorno.
4. Ejecutar `uvicorn app.main:app --reload` desde `backend/`.
5. Ejecutar `pytest -q` desde `backend/`.

Las rutas protegidas requieren `Authorization: Bearer <access_token>` obtenido de Supabase Auth. La API verifica el token mediante `/auth/v1/user`, identifica al usuario por `auth_user_id` y usa ese mismo JWT para las consultas PostgREST; no emplea la clave service_role.

| Ruta | Acceso |
| --- | --- |
| GET /api/v1/health | Público |
| GET /api/v1/products | Catálogo público |
| GET /api/v1/me | Usuario autenticado |
| GET /api/v1/me/orders | Usuario autenticado, pedidos propios |
| GET /api/v1/me/plans | Usuario autenticado, planes propios |
| GET /api/v1/admin/overview | Usuario con permiso administrativo |

**Advertencia:** las rutas nuevas son solo lectura. La aplicación Flutter todavía usa login simulado y no les envía tokens reales. Los pedidos NO se escriben aún en la base de datos. No habilitar ventas reales hasta probar RLS, permisos, pagos e inventario en un entorno de pruebas. La consulta administrativa tiene un límite de 500 registros por tabla y reporta `partial=true` cuando alcanza ese límite; no es un dashboard financiero completo.

No se modificó el código ni el repositorio web.
