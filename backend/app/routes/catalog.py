import os
import httpx
from fastapi import APIRouter, HTTPException

router = APIRouter(tags=['catalog'])

@router.get('/products')
async def list_products():
    base = os.getenv('SUPABASE_URL', '').rstrip('/')
    key = os.getenv('SUPABASE_PUBLISHABLE_KEY', '')
    if not base or not key:
        raise HTTPException(status_code=503, detail='Catálogo no configurado')
    headers = {'apikey': key, 'Authorization': 'Bearer ' + key}
    async with httpx.AsyncClient(timeout=10) as client:
        try:
            response = await client.get(base + '/rest/v1/productos', params={'select': 'id_producto,id_categoria,referencia,nombre_producto,descripcion,estado', 'estado': 'eq.ACTIVO', 'limit': '100'}, headers=headers)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail='No se pudo consultar el catálogo') from exc
    return {'items': response.json()}
