# ModaPlus Mobile API — fase inicial

Backend separado del proyecto web. No modifica MonsalveGod/ModaPlus.

## Ejecutar

```bash
cd backend
python -m venv .venv
pip install -r requirements.txt
# Configura SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY en tu entorno.
uvicorn app.main:app --reload
```

Endpoints: GET /api/v1/health, GET /api/v1/products.

La lectura del catálogo usa clave publicable y políticas RLS. No colocar claves service_role en Flutter. Este es un esqueleto inicial: aún no implementa autenticación, pedidos, pagos ni sincronización bidireccional.
