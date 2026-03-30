#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEFAULT_GCP_CREDENTIALS="$HOME/.config/gcp/london-transport-analytics-sa.json"

create_virtualenv() {
    if command -v uv >/dev/null 2>&1; then
        uv venv --python python3 .venv
    else
        python3 -m venv .venv
    fi
}

install_dashboard_deps() {
    if command -v uv >/dev/null 2>&1; then
        uv pip install --python .venv/bin/python -r dashboard/requirements.txt
    else
        ".venv/bin/python" -m pip install --upgrade pip
        ".venv/bin/python" -m pip install -r dashboard/requirements.txt
    fi
}

if [[ ! -d ".venv" ]]; then
    printf "Creating Python virtual environment...\n"
    create_virtualenv
fi

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" && -f "$DEFAULT_GCP_CREDENTIALS" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$DEFAULT_GCP_CREDENTIALS"
fi

export LTA_BQ_PROJECT_ID="${LTA_BQ_PROJECT_ID:-london-transport-analytics}"
export LTA_BQ_DATASET="${LTA_BQ_DATASET:-london_transport_dw}"
export LTA_BQ_MART_TABLE="${LTA_BQ_MART_TABLE:-transport_journeys_mart}"

printf "Installing dashboard dependencies...\n"
install_dashboard_deps

printf "Starting Streamlit dashboard...\n"
exec ".venv/bin/python" -m streamlit run dashboard/app.py
