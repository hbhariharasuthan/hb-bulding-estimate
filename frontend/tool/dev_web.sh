#!/usr/bin/env bash
# Like `npm run dev` for Vue/Vite: one entrypoint for web on Chrome.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${WEB_PORT:-8081}"

# Prevent repeated "address already in use" from stale flutter/dartvm listeners.
if lsof -nP -iTCP:"${PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "Port ${PORT} is busy. Stopping stale listener..."
  lsof -tiTCP:"${PORT}" -sTCP:LISTEN | xargs -r kill -9
  sleep 1
fi

flutter pub get
exec flutter run -d chrome \
  --web-hostname localhost \
  --web-port "${PORT}" \
  "$@"
