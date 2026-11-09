from fastapi import FastAPI
from .routes.catalog import router as catalog_router
from .routes.account import router as account_router
from .routes.admin import router as admin_router

app = FastAPI(title="ModaPlus Mobile API", version="0.2.0")

@app.get("/api/v1/health")
def health():
    return {"status": "ok", "service": "modaplus-mobile"}

app.include_router(catalog_router, prefix="/api/v1")
app.include_router(account_router, prefix="/api/v1")
app.include_router(admin_router, prefix="/api/v1")
