from app.http.routers import (
    auth_custom_router,
    auth_router,
    config_router,
    material_standards_router,
    plans_router,
    site_settings_router,
)

__all__ = [
    "auth_router",
    "auth_custom_router",
    "plans_router",
    "material_standards_router",
    "config_router",
    "site_settings_router",
]

