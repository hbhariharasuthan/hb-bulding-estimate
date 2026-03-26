from __future__ import annotations

from fastapi.responses import JSONResponse

from app.core.utils.time_helper import TimeHelper


class ApiResponse:
    @staticmethod
    def success(message: str, data: dict | None = None, status_code: int = 200) -> JSONResponse:
        return JSONResponse(
            status_code=status_code,
            content={
                "success": True,
                "message": message,
                "data": data or {},
                "errors": None,
                "meta": {"timestamp": TimeHelper.now_localized()},
            },
        )

    @staticmethod
    def error(
        message: str,
        errors: dict | list | None = None,
        status_code: int = 400,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status_code,
            content={
                "success": False,
                "message": message,
                "data": None,
                "errors": errors or {},
                "meta": {"timestamp": TimeHelper.now_localized()},
            },
        )
