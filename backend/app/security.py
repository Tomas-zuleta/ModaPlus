"""Autenticación Supabase sin service-role: cada consulta conserva el JWT del usuario.

Nunca se acepta un rol enviado por Flutter ni se expone una clave privilegiada.
"""
import os
import httpx
from fastapi import Header, HTTPException

def settings():
    url = os.getenv("SUPABASE_URL", "").rstrip("/")
    key = os.getenv("SUPABASE_PUBLISHABLE_KEY", "")
    if not url.startswith("https://") or not key:
        raise HTTPException(503, "Supabase no está configurado")
    return url, key

async def request_supabase(path: str, token: str, params: dict | None = None):
    url, key = settings()
    headers = {"apikey": key, "Authorization": f"Bearer {token}"}
    try:
        async with httpx.AsyncClient(timeout=12) as client:
            response = await client.get(f"{url}{path}", headers=headers, params=params)
    except httpx.HTTPError as exc:
        raise HTTPException(502, "No se pudo contactar Supabase") from exc
    if response.status_code in (401, 403):
        raise HTTPException(401 if response.status_code == 401 else 403, "Acceso no autorizado")
    if response.status_code >= 400:
        raise HTTPException(502, "Error al consultar datos protegidos")
    return response.json()

async def authenticated_user(authorization: str | None = Header(default=None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(401, "Inicia sesión para continuar")
    token = authorization.removeprefix("Bearer ").strip()
    if not token or len(token) > 8192:
        raise HTTPException(401, "Token inválido")
    user = await request_supabase("/auth/v1/user", token)
    if not isinstance(user, dict) or not user.get("id"):
        raise HTTPException(401, "Sesión inválida")
    return {"id": user["id"], "token": token}

async def current_account(user: dict):
    rows = await request_supabase("/rest/v1/usuarios", user["token"], {
        "select": "id_usuario,id_cliente,estado,clientes(id_cliente,nombres,apellidos,correo,telefono,direccion),usuarios_roles(id_rol)",
        "auth_user_id": f"eq.{user['id']}",
        "limit": "1",
    })
    if not rows or rows[0].get("estado") != "ACTIVO":
        raise HTTPException(403, "La cuenta no está activa")
    row = rows[0]
    if not row.get("clientes"):
        raise HTTPException(403, "Cuenta sin cliente vinculado")
    return row

async def require_admin(user: dict, account: dict):
    role_ids = [x.get("id_rol") for x in account.get("usuarios_roles", [])]
    if not role_ids:
        raise HTTPException(403, "Permisos insuficientes")
    roles = await request_supabase("/rest/v1/roles", user["token"], {
        "select": "id_rol,nombre_rol,estado,roles_permisos(modulos(codigo),permisos(codigo))",
        "id_rol": "in.(" + ",".join(str(int(x)) for x in role_ids) + ")",
    })
    allowed = any(
        r.get("estado") == "ACTIVO" and (
            r.get("nombre_rol") == "SUPER_ADMIN" or any(
                (p.get("permisos") or {}).get("codigo") == "view"
                and (p.get("modulos") or {}).get("codigo") not in ("catalogo", "perfil")
                for p in r.get("roles_permisos", [])
            )
        ) for r in roles
    )
    if not allowed:
        raise HTTPException(403, "Se requieren permisos administrativos")
