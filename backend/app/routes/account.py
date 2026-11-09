"""Lecturas autenticadas de cuenta, compras y planes del usuario."""
from fastapi import APIRouter, Depends
from ..security import authenticated_user, current_account, request_supabase

router = APIRouter(prefix="/me", tags=["account"])

@router.get("")
async def profile(user=Depends(authenticated_user)):
    account = await current_account(user)
    return {"account": account["clientes"], "status": account["estado"]}

@router.get("/orders")
async def my_orders(user=Depends(authenticated_user)):
    account = await current_account(user)
    rows = await request_supabase("/rest/v1/ventas", user["token"], {
        "select": "id_venta,fecha_venta,metodo_pago,subtotal,total_venta,estado,origen,motivo_rechazo,fecha_limite_pago,fecha_entrega",
        "id_cliente": f"eq.{int(account['id_cliente'])}",
        "order": "fecha_venta.desc",
        "limit": "100",
    })
    return {"items": rows}

@router.get("/plans")
async def my_plans(user=Depends(authenticated_user)):
    account = await current_account(user)
    rows = await request_supabase("/rest/v1/planes_separe", user["token"], {
        "select": "id_plan_separe,fecha_inicio,fecha_vencimiento,estado,fecha_estado",
        "id_cliente": f"eq.{int(account['id_cliente'])}",
        "order": "fecha_inicio.desc",
        "limit": "100",
    })
    return {"items": rows}
