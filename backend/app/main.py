from fastapi import FastAPI
from .routes.catalog import router as catalog_router

app = FastAPI(title='ModaPlus Mobile API', version='0.1.0')

@app.get('/api/v1/health')
def health():
    return {'status': 'ok', 'service': 'modaplus-mobile'}

app.include_router(catalog_router, prefix='/api/v1')
