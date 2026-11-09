"""Resumen administrativo de solo lectura; Supabase RLS sigue aplicándose."""
from fastapi import APIRouter, Depends
from ..security import authenticated_user, current_account, require_admin, request_supabase

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/overview")
async def overview(user=Depends(authenticated_user)):
    account = await current_account(user)
    await require_admin(user, account)
    orders = await request_supabase("/rest/v1/ventas", user["token"], {
        "select": "id_venta,fecha_venta,total_venta,estado,origen",
        "order": "fecha_venta.desc", "limit": "500",
    })
    variants = await request_supabase("/rest/v1/variantes_producto", user["token"], {
        "select": "id_variante,id_producto,stock_actual,stock_minimo,estado", "limit": "500",
    })
    pending = [o for o in orders if str(o.get("estado", "")).upper() in ("PENDIENTE", "PENDIENTE_APROBACION")]
    low = [v for v in variants if v.get("estado") == "ACTIVO" and
           int(v.get("stock_actual") or 0) <= int(v.get("stock_minimo") or 0)]
    return {
        "source": "supabase",
        "partial": len(orders) == 500 or len(variants) == 500,
        "orders_checked": len(orders),
        "pending_orders": len(pending),
        "low_stock_count": len(low),
        "stock_units_checked": sum(int(v.get("stock_actual") or 0) for v in variants),
        "alerts": (
            [{"type": "order_pending", "id": o["id_venta"]} for o in pending[:15]] +
            [{"type": "low_stock", "id": v["id_variante"], "stock": v["stock_actual"]}
             for v in low[:15]]
        ),
    }
