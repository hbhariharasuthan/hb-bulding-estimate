#!/usr/bin/env bash
# Like `npm run dev` for Vue/Vite: one entrypoint for web on Chrome.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
exec flutter run -d chrome \
  --web-hostname localhost \
  --web-port 8081 \
  "$@"
