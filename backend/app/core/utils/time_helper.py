from __future__ import annotations

from datetime import UTC, datetime


class TimeHelper:
    @staticmethod
    def now_localized() -> str:
        return datetime.now(UTC).isoformat()
