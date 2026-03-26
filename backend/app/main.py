from fastapi import FastAPI

from app.http import (
    auth_custom_router,
    auth_router,
    config_router,
    material_standards_router,
    plans_router,
)

app = FastAPI(
    title="Building Estimate API",
    description="API for building estimates with custom RBAC, JWT authentication, and MVC-style auth endpoint.",
    version="1.0.0",
    swagger_ui_parameters={"defaultModelsExpandDepth": -1},
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def root():
    return {"message": "Building Estimate API"}


app.include_router(auth_router)
app.include_router(auth_custom_router)
app.include_router(plans_router)
app.include_router(material_standards_router)
app.include_router(config_router)
