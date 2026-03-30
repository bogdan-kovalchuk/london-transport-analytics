#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_PATH="${1:-$HOME/.config/gcp/london-transport-analytics-sa.json}"
ENV_PATH="$ROOT_DIR/Kestra/.env"

if [[ ! -f "$KEY_PATH" ]]; then
    printf "Service account key not found: %s\n" "$KEY_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$ENV_PATH")"

python3 - <<'PY' "$KEY_PATH" "$ENV_PATH"
import base64
import pathlib
import sys

key_path = pathlib.Path(sys.argv[1])
env_path = pathlib.Path(sys.argv[2])
raw_bytes = key_path.read_bytes()
payload = base64.b64encode(raw_bytes).decode("ascii")
payload_b64 = base64.b64encode(payload.encode("ascii")).decode("ascii")
env_path.write_text(
    (
        f"SECRET_GCP_SERVICE_ACCOUNT={payload}\n"
        f"SECRET_GCP_SERVICE_ACCOUNT_B64={payload_b64}\n"
    ),
    encoding="utf-8",
)
PY

chmod 600 "$ENV_PATH"
printf "Kestra secret env file updated at %s\n" "$ENV_PATH"
