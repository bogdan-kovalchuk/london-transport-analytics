#!/usr/bin/env bash

set -euo pipefail

resolve_command_path() {
    local command_name="$1"

    if command -v "$command_name" >/dev/null 2>&1; then
        command -v "$command_name"
        return 0
    fi

    case "$command_name" in
        terraform)
            if [[ -x "$HOME/.local/bin/terraform" ]]; then
                printf "%s\n" "$HOME/.local/bin/terraform"
                return 0
            fi
            ;;
        gcloud)
            if [[ -x "$HOME/.local/google-cloud-sdk/bin/gcloud" ]]; then
                printf "%s\n" "$HOME/.local/google-cloud-sdk/bin/gcloud"
                return 0
            fi
            ;;
    esac

    return 1
}

print_tool_status() {
    local name="$1"
    local command_name="$2"
    local required="$3"
    local version_args="$4"
    local path=""
    local status="Missing"
    local version=""

    if path="$(resolve_command_path "$command_name" 2>/dev/null)"; then
        status="Found"
        if version="$("$path" $version_args 2>/dev/null | head -n 1)"; then
            :
        else
            version="Detected, but version lookup failed"
        fi
    fi

    printf "%-20s %-8s %-45s %s\n" "$name" "$status" "${path:--}" "${version:--}"

    if [[ "$required" == "true" && "$status" == "Missing" ]]; then
        return 1
    fi

    return 0
}

printf "%-20s %-8s %-45s %s\n" "Tool" "Status" "Path" "Version"
printf "%-20s %-8s %-45s %s\n" "----" "------" "----" "-------"

missing_required=0

print_tool_status "Python" "python3" "true" "--version" || missing_required=1
print_tool_status "Terraform" "terraform" "true" "version" || missing_required=1
print_tool_status "Google Cloud SDK" "gcloud" "true" "version" || missing_required=1
print_tool_status "Docker" "docker" "true" "--version" || missing_required=1
print_tool_status "Docker Compose" "docker" "true" "compose version" || missing_required=1

if [[ "$missing_required" -ne 0 ]]; then
    printf "\nMissing tools detected. Run scripts/bootstrap_linux.sh and reopen the shell if needed.\n" >&2
    exit 1
fi
