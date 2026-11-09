import asyncio
import pytest
from fastapi import HTTPException
from app.security import authenticated_user, require_admin

def test_rejects_missing_token():
    with pytest.raises(HTTPException) as err:
        asyncio.run(authenticated_user(None))
    assert err.value.status_code == 401

def test_rejects_bad_token():
    with pytest.raises(HTTPException) as err:
        asyncio.run(authenticated_user("Basic invalid"))
    assert err.value.status_code == 401

def test_rejects_non_admin(monkeypatch):
    from app import security
    async def fake_request(path, token, params=None):
        return [{"estado": "ACTIVO", "nombre_rol": "CLIENTE", "roles_permisos": []}]
    monkeypatch.setattr(security, "request_supabase", fake_request)
    with pytest.raises(HTTPException) as err:
        asyncio.run(require_admin({"token": "test"}, {"usuarios_roles": [{"id_rol": 4}]}))
    assert err.value.status_code == 403

def test_accepts_admin_permission(monkeypatch):
    from app import security
    async def fake_request(path, token, params=None):
        return [{"estado": "ACTIVO", "nombre_rol": "ADMIN", "roles_permisos": [
            {"modulos": {"codigo": "ventas"}, "permisos": {"codigo": "view"}}
        ]}]
    monkeypatch.setattr(security, "request_supabase", fake_request)
    asyncio.run(require_admin({"token": "test"}, {"usuarios_roles": [{"id_rol": 2}]}))
