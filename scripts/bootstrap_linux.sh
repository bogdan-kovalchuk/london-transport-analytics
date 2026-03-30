#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INSTALL_DOCKER=false
INSTALL_DASHBOARD_DEPS=false
LOCAL_BIN_DIR="$HOME/.local/bin"
GCLOUD_INSTALL_DIR="$HOME/.local/google-cloud-sdk"
PATH_SNIPPET='export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"'

for arg in "$@"; do
    case "$arg" in
        --install-docker)
            INSTALL_DOCKER=true
            ;;
        --install-dashboard-deps)
            INSTALL_DASHBOARD_DEPS=true
            ;;
        *)
            printf "Unknown argument: %s\n" "$arg" >&2
            printf "Usage: %s [--install-docker] [--install-dashboard-deps]\n" "${BASH_SOURCE[0]}" >&2
            exit 1
            ;;
    esac
done

mkdir -p "$LOCAL_BIN_DIR"

ensure_path_snippet() {
    if ! grep -Fq "$PATH_SNIPPET" "$HOME/.bashrc" 2>/dev/null; then
        printf "\n# London Transport Analytics local toolchain\n%s\n" "$PATH_SNIPPET" >> "$HOME/.bashrc"
    fi

    export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
}

install_terraform() {
    if command -v terraform >/dev/null 2>&1; then
        printf "Terraform is already installed.\n"
        return
    fi

    printf "Installing Terraform locally in %s...\n" "$LOCAL_BIN_DIR"

    local tf_version
    local tf_zip
    local tmp_dir

    tf_version="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | python3 -c 'import json,sys; print(json.load(sys.stdin)["current_version"])')"
    tf_zip="terraform_${tf_version}_linux_amd64.zip"
    tmp_dir="$(mktemp -d)"

    curl -fsSL "https://releases.hashicorp.com/terraform/${tf_version}/${tf_zip}" -o "$tmp_dir/$tf_zip"
    python3 - <<'PY' "$tmp_dir/$tf_zip" "$LOCAL_BIN_DIR/terraform"
import os
import stat
import sys
import zipfile

zip_path, output_path = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as archive:
    with archive.open("terraform") as src, open(output_path, "wb") as dst:
        dst.write(src.read())

mode = os.stat(output_path).st_mode
os.chmod(output_path, mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
PY

    rm -rf "$tmp_dir"
}

install_gcloud() {
    if command -v gcloud >/dev/null 2>&1; then
        printf "Google Cloud SDK is already installed.\n"
        return
    fi

    printf "Installing Google Cloud SDK locally in %s...\n" "$GCLOUD_INSTALL_DIR"

    local archive_name="google-cloud-cli-linux-x86_64.tar.gz"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    rm -rf "$GCLOUD_INSTALL_DIR"
    curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${archive_name}" -o "$tmp_dir/$archive_name"
    tar -xzf "$tmp_dir/$archive_name" -C "$HOME/.local"

    "$GCLOUD_INSTALL_DIR/install.sh" \
        --quiet \
        --path-update=false \
        --command-completion=false \
        --usage-reporting=false \
        --bash-completion=false

    rm -rf "$tmp_dir"
}

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        printf "Docker is already installed.\n"
        return
    fi

    printf "Docker is not installed.\n" >&2
    printf "Install Docker Desktop with WSL2 integration or a native Docker Engine package before starting Kestra.\n" >&2
    exit 1
}

create_virtualenv() {
    if command -v uv >/dev/null 2>&1; then
        uv venv --python python3 .venv
    else
        python3 -m venv .venv
    fi
}

install_dashboard_deps() {
    if [[ ! -d ".venv" ]]; then
        printf "Creating Python virtual environment...\n"
        create_virtualenv
    fi

    printf "Installing dashboard dependencies...\n"
    if command -v uv >/dev/null 2>&1; then
        uv pip install --python .venv/bin/python -r dashboard/requirements.txt
    else
        ".venv/bin/python" -m pip install --upgrade pip
        ".venv/bin/python" -m pip install -r dashboard/requirements.txt
    fi
}

ensure_path_snippet
install_terraform
install_gcloud

if [[ "$INSTALL_DOCKER" == "true" ]]; then
    install_docker
fi

if [[ "$INSTALL_DASHBOARD_DEPS" == "true" ]]; then
    install_dashboard_deps
fi

printf "\nBootstrap finished.\n"
printf "If Terraform or gcloud are still not available in the current terminal, run: %s\n" "$PATH_SNIPPET"
printf "If you installed Docker in WSL2, ensure the daemon is running before starting Kestra.\n"
