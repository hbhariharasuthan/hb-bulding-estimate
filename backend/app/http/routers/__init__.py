from .auth import router as auth_router
from .auth_custom import router as auth_custom_router
from .config import router as config_router
from .material_standards import router as material_standards_router
from .plans import router as plans_router
from .site_settings import router as site_settings_router

__all__ = [
    "auth_router",
    "auth_custom_router",
    "plans_router",
    "material_standards_router",
    "config_router",
    "site_settings_router",
]

