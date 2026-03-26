from __future__ import annotations

ROLE_PERMISSIONS: dict[str, set[str]] = {
    "admin": {
        "users:read",
        "users:write",
        "plans:read",
        "plans:write",
        "estimates:read",
        "estimates:write",
    },
    "member": {
        "plans:read",
        "plans:write",
        "estimates:read",
    },
}

