"""OpenAPI: register JWT Bearer in Swagger for protected paths."""

from __future__ import annotations

from collections.abc import Callable

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

BEARER_KEY = "BearerAuth"
BEARER_RULE = {BEARER_KEY: []}
_HTTP = frozenset({"get", "post", "put", "patch", "delete", "head", "options"})
_ME = frozenset({"/auth/me", "/api/v1/auth/me"})
_PREFIXES = ("/plans", "/users")


def _under(path: str, prefix: str) -> bool:
    return path == prefix or path.startswith(prefix + "/")


def path_needs_bearer(path: str) -> bool:
    if path in _ME:
        return True
    return any(_under(path, p) for p in _PREFIXES)


def register_bearer_scheme(components: dict) -> None:
    schemes = components.setdefault("securitySchemes", {})
    schemes.setdefault(
        BEARER_KEY,
        {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": (
                "From POST /auth/jwt/login or POST /api/v1/auth/login "
                "(`data.access_token`). TTL ~24h."
            ),
        },
    )


def attach_bearer_to_paths(paths: dict) -> None:
    for path, ops in paths.items():
        if not path_needs_bearer(path):
            continue
        for method, op in ops.items():
            if method not in _HTTP or not isinstance(op, dict):
                continue
            sec = op.setdefault("security", [])
            if BEARER_RULE not in sec:
                sec.append(BEARER_RULE)


def build_openapi(app: FastAPI) -> dict:
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    register_bearer_scheme(schema.setdefault("components", {}))
    attach_bearer_to_paths(schema.get("paths", {}))
    return schema


def openapi_generator(app: FastAPI) -> Callable[[], dict]:
    def generate() -> dict:
        if app.openapi_schema:
            return app.openapi_schema
        app.openapi_schema = build_openapi(app)
        return app.openapi_schema

    return generate
