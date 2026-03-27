import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.openapi import openapi_generator
from app.http import (
    auth_custom_router,
    auth_router,
    config_router,
    material_standards_router,
    plans_router,
    preprocessing_router,
    site_settings_router,
)

app = FastAPI(
    title="Building Estimate API",
    description="API for building estimates with custom RBAC, JWT authentication, and MVC-style auth endpoint.",
    version="1.0.0",
    swagger_ui_parameters={"defaultModelsExpandDepth": -1},
)

# CORS: register immediately after creating the app (FastAPI docs). JWT via Authorization
# does not need credentialed CORS — allow_credentials=False avoids browser preflight issues.
_default_origins = (
    "http://localhost:8080,"
    "http://127.0.0.1:8080,"
    "http://localhost:8081,"
    "http://127.0.0.1:8081,"
    "http://localhost:5173,"
    "http://127.0.0.1:5173"
)


def _parse_cors_origins() -> list[str]:
    raw = os.environ.get("CORS_ORIGINS", _default_origins)
    out = [o.strip() for o in raw.split(",") if o.strip()]
    return out or [o.strip() for o in _default_origins.split(",") if o.strip()]


def _env_truthy(name: str) -> bool:
    return os.environ.get(name, "").lower() in ("1", "true", "yes", "on")


def _install_cors() -> None:
    # Nuclear dev option: any origin, no credentials (fine for Bearer APIs).
    if _env_truthy("CORS_ALLOW_ALL"):
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=False,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        return

    _localhost_origin_regex = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_parse_cors_origins(),
        allow_origin_regex=_localhost_origin_regex,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )


_install_cors()

# Laravel-style public storage namespace for uploaded assets.
_storage_public_dir = Path(__file__).resolve().parents[1] / "storage" / "app" / "public"
_storage_public_dir.mkdir(parents=True, exist_ok=True)
app.mount("/storage", StaticFiles(directory=str(_storage_public_dir)), name="storage")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def root():
    return {"message": "Building Estimate API"}


app.include_router(auth_router)
app.include_router(auth_custom_router)
app.include_router(plans_router)
app.include_router(preprocessing_router)
app.include_router(material_standards_router)
app.include_router(config_router)
app.include_router(site_settings_router)

app.openapi = openapi_generator(app)
