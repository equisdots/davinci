#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Legacy entry point for the davinci kernel. New callers should use davinci.sh
# or the ~/.local/bin/davinci wrapper; this file keeps old checkouts working.
# ---------------------------------------------------------------------------
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/davinci.sh" "$@"
