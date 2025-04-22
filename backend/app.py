"""
backend/app.py
--------------
FastAPI application factory, middleware, and router includes.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.config import settings
from backend.db.database import init_models
from backend.routers.files import router as files_router
from backend.routers.projects import router as projects_router
# Temporarily disabled for simplified startup
# from backend.routers.intelligence import router as intel_router

def create_app() -> FastAPI:
    app = FastAPI(
        title="Legal Assistant AI",
        version="0.1.0",
        description="Post‑Trial Appeals Workbench",
    )

    # CORS setup
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],           # tighten in prod
        allow_methods=["*"],
        allow_headers=["*"],
        allow_credentials=True,
    )

    # Mount auth router
    from backend.routers.auth import router as auth_router
    app.include_router(auth_router, prefix="/auth", tags=["auth"])

    # Mount routers
    app.include_router(files_router,    prefix="/files",       tags=["files"])
    app.include_router(projects_router, prefix="/projects",    tags=["projects"])
    # Intelligence router temporarily disabled
    # app.include_router(intel_router,    prefix="/intelligence", tags=["intelligence"])
    
    # Health check endpoint
    @app.get("/health", tags=["health"])
    async def health_check():
        return {"status": "ok", "version": app.version}

    # Dev‑only: auto‑create tables on startup
    @app.on_event("startup")
    async def on_startup():
        if settings.is_dev:
            await init_models()

    return app


# Instantiate for Gunicorn/Uvicorn
app = create_app()